import { type Request, type Response } from "express";
import { logger } from "../../utils/logger";
import { getPrisma } from "../../utils/prisma";
import { discordApiUrl } from "../../utils/constants";
import { parseDuration, InvalidDurationError } from "../../utils/duration";

export const kickUser = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;
  const userId = req.params["userId"] as string;
  const moderatorId = req.body["moderatorId"] as string;
  const reason = req.body["reason"] as string;
  const rawDuration = req.body["duration"] as string | undefined;
  const prisma = getPrisma();

  let duration: number | undefined;
  if (rawDuration) {
    try {
      duration = parseDuration(rawDuration); // seconds
    } catch (err) {
      if (err instanceof InvalidDurationError) {
        return res.status(400).json({ error: err.message });
      }
      throw err;
    }
  }

  try {
    const member = await prisma.guildMember.findFirst({
      where: { userId: userId, guildId: guildId },
    });

    if (!duration) {
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

      return res.status(202).json({ log });
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

      const expiresAt = new Date(Date.now() + duration * 1000);

      const ban = await prisma.ban.create({
        data: {
          reason: reason,
          guildId: guildId,
          userId: userId,
          moderatorId: moderatorId,
          memberId: member?.id ?? null,
          active: true,
          duration: duration,
          expiresAt: expiresAt,
        },
      });

      const log = await prisma.log.create({
        data: {
          action: "BAN",
          reason: reason,
          duration: duration,
          expiresAt: expiresAt,
          guildId: guildId,
          targetId: userId,
          moderatorId: moderatorId,
          memberId: member?.id ?? null,
          banId: ban.id,
        },
      });

      return res.status(202).json({ ban, log });
    }
  } catch (err) {
    logger.error("An error occurred during kick/soft-ban:", err);
    return res.status(500).json({
      error: "Internal Server Error",
    });
  }
};
