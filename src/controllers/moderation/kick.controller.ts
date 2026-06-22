import { type Request, type Response } from "express";
import { logger } from "../../utils/logger";
import { getPrisma } from "../../utils/prisma";
import { discordApiUrl } from "../../utils/constants";

export const kickUser = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;
  const userId = req.params["userId"] as string;
  const moderatorId = req.body["moderatorId"] as string;
  const reason = req.body["reason"] as string;
  const duration = req.body["duration"] as number;
  const prisma = getPrisma();

  try {
    if (duration === null) {
      const discordResponse = await fetch(
        `${discordApiUrl}/guilds/${guildId}/members/${userId}`,
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
          `Discord API kick failed for user ${userId} in guild ${guildId}`,
        );
        return res.status(discordResponse.status).json({
          error: "Failed to kick user on Discord",
        });
      }

      const member = await prisma.guildMember.findFirst({
        where: { userId: userId, guildId: guildId },
      });

      const log = await prisma.log.create({
        data: {
          action: "KICK",
          reason: reason,
          guildId: guildId,
          targetId: userId,
          moderatorId: moderatorId,
          memberId: member?.id ?? null,
        },
      });

      res.status(202).json({
        log: log,
      });
    } else {
      const discordResponse = await fetch(
        `${discordApiUrl}/guilds/${guildId}/bans/${userId}`,
        {
          method: "PUT",
          headers: {
            Authorization: `Bot ${process.env.MODERATION_BOT_TOKEN}`,
            "User-Agent": "DiscordBot",
            "X-Audit-Log-Reason": reason,
          },
        },
      );

      if (!discordResponse.ok) {
        logger.error(
          `Discord API ban failed for user ${userId} in guild ${guildId}`,
        );
        return res.status(discordResponse.status).json({
          error: "Failed to ban user on Discord",
        });
      }

      const member = await prisma.guildMember.findFirst({
        where: { userId: userId, guildId: guildId },
      });

      const log = await prisma.log.create({
        data: {
          action: "BAN",
          reason: reason,
          duration: duration,
          guildId: guildId,
          targetId: userId,
          moderatorId: moderatorId,
          memberId: member?.id ?? null,
        },
      });

      res.status(202).json({
        log,
      });
    }
  } catch (err) {
    res.status(500).json({
      error: err,
    });
  }
};
