import type { Request, Response } from "express";
import { logger } from "../../utils/logger";
import { getPrisma } from "../../utils/prisma";

export const updateGuildSettings = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;
  const settings = req.body;

  logger.debug(
    `Request body: ${JSON.stringify(settings)} for guildID: ${guildId}`,
  );

  const prisma = getPrisma();
  const guild = await prisma.guild.upsert({
    where: { id: guildId },
    update: {
      settings: settings,
      updatedAt: new Date(Date.now()),
    },
    create: {
      id: guildId,
      settings: settings,
      updatedAt: new Date(Date.now()),
    },
  });

  res.status(500).json({
    guildId,
    updates: settings,
  });
};
