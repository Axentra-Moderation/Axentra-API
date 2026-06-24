import { type Request, type Response } from "express";
import { logger } from "../../../utils/logger";
import { getPrisma } from "../../../utils/prisma";
import { discordApiUrl } from "../../../utils/constants";
import { parseDuration, InvalidDurationError } from "../../../utils/duration";

export const muteUser = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;
  const userId = req.params["userId"] as string;
  const moderatorId = req.body["moderatorId"] as string;
  const reason = req.body["reason"] as string;
  const rawDuration = req.body["duration"] as string | undefined;
  const prisma = getPrisma();

  if (!rawDuration) {
    return res
      .status(400)
      .json({ error: "A duration is required to mute a user." });
  }

  let duration: number;
  try {
    duration = parseDuration(rawDuration); // seconds
  } catch (err) {
    if (err instanceof InvalidDurationError) {
      return res.status(400).json({ error: err.message });
    }
    throw err;
  }

  // Discord caps timeouts at 28 days
  const MAX_TIMEOUT_SECONDS = 28 * 24 * 60 * 60;
  if (duration > MAX_TIMEOUT_SECONDS) {
    return res.status(400).json({
      error: "Timeout duration cannot exceed 28 days.",
    });
  }

  const communicationDisabledUntil = new Date(Date.now() + duration * 1000);

  try {
    const member = await prisma.guildMember.findFirst({
      where: { userId: userId, guildId: guildId },
    });

    const discordResponse = await fetch(
      `${discordApiUrl}/guilds/${guildId}/members/${userId}`,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bot ${process.env.MODERATION_BOT_TOKEN}`,
          "User-Agent": "DiscordBot",
          "Content-Type": "application/json",
          "X-Audit-Log-Reason": reason,
        },
        body: JSON.stringify({
          communication_disabled_until:
            communicationDisabledUntil.toISOString(),
        }),
      },
    );

    if (!discordResponse.ok) {
      logger.error(
        `Discord API mute failed for user ${userId} in guild ${guildId}`,
      );
      return res.status(discordResponse.status).json({
        error: "Failed to mute user on Discord",
      });
    }

    if (member) {
      await prisma.guildMember.update({
        where: { id: member.id },
        data: { communicationDisabledUntil: communicationDisabledUntil },
      });
    }

    const log = await prisma.log.create({
      data: {
        action: "MUTE",
        reason: reason,
        duration: duration,
        expiresAt: communicationDisabledUntil,
        guildId: guildId,
        targetId: userId,
        moderatorId: moderatorId,
        memberId: member?.id ?? null,
      },
    });

    return res.status(200).json({ log });
  } catch (err) {
    logger.error("An error occurred during user mute:", err);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};
