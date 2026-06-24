import { type Request, type Response } from "express";
import { logger } from "../../../utils/logger";
import { getPrisma } from "../../../utils/prisma";
import { discordApiUrl } from "../../../utils/constants";

export const unmuteUser = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;
  const userId = req.params["userId"] as string;
  const moderatorId = req.body["moderatorId"] as string;
  const reason = req.body["reason"] as string;
  const prisma = getPrisma();

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
          communication_disabled_until: null,
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
        data: { communicationDisabledUntil: null },
      });
    }

    const log = await prisma.log.create({
      data: {
        action: "UNMUTE",
        reason: reason,
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
