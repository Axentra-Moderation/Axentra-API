import "dotenv/config";
import type { Request, Response } from "express";
import { signJwt } from "../../utils/jwt.js";
import { logger } from "../../utils/logger.js";
import { getPrisma } from "../../utils/prisma.js";

export const discordCallback = async (req: Request, res: Response) => {
  const { code } = req.query;

  // 1. Exchange code for Discord token
  const tokenRes = await fetch("https://discord.com/api/oauth2/token", {
    method: "POST",
    body: new URLSearchParams({
      client_id: process.env.DISCORD_CLIENT_ID!,
      client_secret: process.env.DISCORD_CLIENT_SECRET!,
      grant_type: "authorization_code",
      code: code as string,
      redirect_uri: process.env.DISCORD_REDIRECT_URI!,
    }),
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });

  const tokenData = await tokenRes.json();
  logger.debug(`Token data: ${JSON.stringify(tokenData)}`);

  if (tokenData.error) {
    res.status(401).json({ error: tokenData.error });
    return;
  }

  // 2. Fetch Discord user
  const userRes = await fetch("https://discord.com/api/users/@me", {
    headers: { Authorization: `Bearer ${tokenData.access_token}` },
  });
  const discordUser = await userRes.json();

  // 3. Upsert user in DB
  const prisma = getPrisma();
  const user = await prisma.user.upsert({
    where: { id: discordUser.id },
    update: {
      username: discordUser.username,
      globalName: discordUser.global_name ?? null,
      avatar: discordUser.avatar ?? null,
      discordAccessToken: tokenData.access_token,
      discordRefreshToken: tokenData.refresh_token,
      discordTokenExpiry: new Date(Date.now() + tokenData.expires_in * 1000),
    },
    create: {
      id: discordUser.id,
      username: discordUser.username,
      globalName: discordUser.global_name ?? null,
      avatar: discordUser.avatar ?? null,
      discordAccessToken: tokenData.access_token,
      discordRefreshToken: tokenData.refresh_token,
      discordTokenExpiry: new Date(Date.now() + tokenData.expires_in * 1000),
    },
  });

  // 4. Issue JWT
  const token = signJwt({ id: user.id, username: user.username });

  res.json({
    token,
    user: {
      id: user.id,
      username: user.username,
      avatar: user.avatar,
      globalName: user.globalName,
    },
  });
};
