import type { Request, Response } from "express";
import { getPrisma } from "../../utils/prisma";

export const getGuildSettings = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;

  const prisma = getPrisma();
  const guild = await prisma.guild.findUnique({
    where: { id: guildId },
  });

  if (!guild) {
    res.status(404).json({ error: "Guild not found" });
    return;
  }

  res.json(guild);
};
