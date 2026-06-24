import { type Request, type Response } from "express";
import { logger } from "../../../utils/logger";
import { getPrisma } from "../../../utils/prisma";
import { discordApiUrl } from "../../../utils/constants";

export const unbanUser = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;
  const userId = req.params["userId"] as string;
  const moderatorId = req.body["moderatorId"] as string;
  const reason = req.body["reason"] as string;
  const prisma = getPrisma();

  try {
    const ban = await prisma.ban.findFirst({
      where: { userId: userId, guildId: guildId },
    });

    if (!ban) {
      return res.status(404).json({
        error: "User not banned.",
      });
    }

    const discordResponse = await fetch(
      `${discordApiUrl}/guilds/${guildId}/bans/${userId}`,
      {
        method: "DELETE",
        headers: {
          Authorization: `Bot ${process.env.MODERATION_BOT_TOKEN}`,
          "User-Agent": "DiscordBot",
          "X-Audit-Log-Reason": reason,
        },
      },
    );

    if (!discordResponse.ok) {
      logger.error(
        `Discord API un-ban failed for user ${userId} in guild ${guildId}`,
      );
      return res.status(discordResponse.status).json({
        error: "Failed to un-ban user on Discord",
      });
    }

    const deleteBan = await prisma.ban.delete({
      where: { id: ban.id },
    });

    const log = await prisma.log.create({
      data: {
        action: "UNBAN",
        reason: reason,
        guildId: guildId,
        targetId: userId,
        moderatorId: moderatorId,
      },
    });

    return res.status(200).json({
      log: log,
    });
  } catch (err) {
    return res.status(500).json({
      error: err,
    });
  }
};
