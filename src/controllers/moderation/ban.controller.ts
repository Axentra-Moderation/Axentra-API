import { type Request, type Response } from "express";
import { logger } from "../../utils/logger";
import { getPrisma } from "../../utils/prisma";
import { discordApiUrl } from "../../utils/constants";

export const banUser = async (req: Request, res: Response) => {
  const guildId = req.params["guildId"] as string;
  const userId = req.params["userId"] as string;
  const moderatorId = req.body["moderatorId"] as string;
  const reason = req.body["reason"] as string;
  const prisma = getPrisma();

  try {
    const userBans = await prisma.ban.findMany({
      where: { guildId: guildId, userId: userId },
    });

    if (userBans.length >= 1) {
      return res.status(302).json({
        error: "This user is already banned from that guild.",
        log: userBans,
      });
    }

    // 1. Call Discord API to execute the ban
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

    // If Discord rejects the ban, stop here and inform the client
    if (!discordResponse.ok) {
      logger.error(
        `Discord API ban failed for user ${userId} in guild ${guildId}`,
      );
      return res.status(discordResponse.status).json({
        error: "Failed to ban user on Discord",
      });
    }

    const log = await prisma.ban.create({
      data: {
        reason: reason,
        guildId: guildId,
        userId: userId,
        moderatorId: moderatorId,
        active: true,
      },
    });

    // 3. Send successful response and return early
    return res.status(200).json({
      log,
    });
  } catch (err) {
    logger.error("An error occurred during user banning:", err);

    // 4. Return early to prevent the 200 response from trying to fire
    return res.status(500).json({
      error: "Internal Server Error",
    });
  }
};
