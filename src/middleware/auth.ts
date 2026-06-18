// src/middleware/auth.ts
import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import { apiKeyRepo } from "../repositories/apiKey.repo";

// Extend Express Request to carry caller identity downstream
declare global {
  namespace Express {
    interface Request {
      caller: Caller;
    }
  }
}

type BotCaller = {
  type: "BOT";
  keyId: string;
};

type DashboardCaller = {
  type: "DASHBOARD_USER";
  userId: string;
  guildPermissions: Record<string, string>; // guildId -> PermissionLevel
};

export type Caller = BotCaller | DashboardCaller;

// ---

export async function auth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    res
      .status(401)
      .json({ error: "Missing or malformed Authorization header" });
    return;
  }

  const token = authHeader.slice(7).trim(); // strip "Bearer "

  // API keys always start with the "mod_pk_" prefix
  if (token.startsWith("mod_pk_")) {
    return handleApiKey(token, req, res, next);
  }

  // Otherwise assume it's a JWT from the dashboard OAuth2 flow
  return handleJwt(token, req, res, next);
}

// --- Bot: static API key ---

async function handleApiKey(
  raw: string,
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const hash = crypto.createHash("sha256").update(raw).digest("hex");

  let apiKey;
  try {
    apiKey = await apiKeyRepo.findByHash(hash);
  } catch {
    res.status(500).json({ error: "Internal server error" });
    return;
  }

  if (!apiKey) {
    res.status(401).json({ error: "Invalid API key" });
    return;
  }

  if (apiKey.revokedAt) {
    res.status(401).json({ error: "API key has been revoked" });
    return;
  }

  if (apiKey.expiresAt && apiKey.expiresAt < new Date()) {
    res.status(401).json({ error: "API key has expired" });
    return;
  }

  // Debounced touch — only update lastUsedAt if it's been more than 5 minutes
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
  if (!apiKey.lastUsedAt || apiKey.lastUsedAt < fiveMinutesAgo) {
    apiKeyRepo.touch(apiKey.id).catch(() => {
      // Non-critical — don't fail the request if this write fails
    });
  }

  req.caller = { type: "BOT", keyId: apiKey.id };
  next();
}

// --- Dashboard: Discord OAuth2 JWT ---

async function handleJwt(
  token: string,
  req: Request,
  res: Response,
  next: NextFunction,
) {
  let payload: jwt.JwtPayload;

  try {
    payload = jwt.verify(token, process.env.JWT_SECRET!) as jwt.JwtPayload;
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      res.status(401).json({ error: "JWT has expired" });
      return;
    }
    res.status(401).json({ error: "Invalid JWT" });
    return;
  }

  if (!payload.sub || !payload.guildPermissions) {
    res.status(401).json({ error: "Malformed JWT payload" });
    return;
  }

  req.caller = {
    type: "DASHBOARD_USER",
    userId: payload.sub,
    guildPermissions: payload.guildPermissions,
  };

  next();
}
