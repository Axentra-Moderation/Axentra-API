import type { Request, Response } from "express";
import { signJwt, verifyJwt } from "../../utils/jwt";

export const refreshToken = (req: Request, res: Response) => {
  const { token } = req.body;

  try {
    const payload = verifyJwt(token);
    const newToken = signJwt({ id: payload.id, username: payload.username });
    res.json({ token: newToken });
  } catch {
    res.status(401).json({ error: "Invalid or expired token" });
  }
};
