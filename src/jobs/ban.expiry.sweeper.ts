import { getPrisma } from "../utils/prisma";
import { logger } from "../utils/logger";
import { discordApiUrl } from "../utils/constants";

const SWEEP_INTERVAL_MS = 60 * 1000; // check every 60 seconds

async function sweepExpiredBans() {
  const prisma = getPrisma();

  const expired = await prisma.ban.findMany({
    where: {
      active: true,
      expiresAt: { not: null, lte: new Date() },
    },
  });

  for (const ban of expired) {
    try {
      const discordResponse = await fetch(
        `${discordApiUrl}/guilds/${ban.guildId}/bans/${ban.userId}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bot ${process.env.MODERATION_BOT_TOKEN}`,
            "User-Agent": "DiscordBot",
            "X-Audit-Log-Reason": "Temporary ban expired",
          },
        },
      );

      // 404 from Discord just means they're already not banned (e.g. manually
      // unbanned already) — treat that as success for cleanup purposes too.
      if (!discordResponse.ok && discordResponse.status !== 404) {
        logger.error(
          `Failed to auto-unban user ${ban.userId} in guild ${ban.guildId}: ${discordResponse.status}`,
        );
        continue; // leave it active, retry next sweep
      }

      await prisma.ban.delete({ where: { id: ban.id } });

      await prisma.log.create({
        data: {
          action: "UNBAN",
          reason: "Temporary ban expired",
          guildId: ban.guildId,
          targetId: ban.userId,
          moderatorId: ban.moderatorId,
          memberId: ban.memberId,
        },
      });

      logger.info(
        `Auto-unbanned user ${ban.userId} in guild ${ban.guildId} (temp ban expired)`,
      );
    } catch (err) {
      logger.error(
        `Error while auto-unbanning user ${ban.userId} in guild ${ban.guildId}:`,
        err,
      );
      // leave it active, retry next sweep
    }
  }
}

export function startBanExpirySweeper() {
  // Run once on startup, then on the interval
  sweepExpiredBans().catch((err) =>
    logger.error("Initial ban expiry sweep failed:", err),
  );

  setInterval(() => {
    sweepExpiredBans().catch((err) =>
      logger.error("Ban expiry sweep failed:", err),
    );
  }, SWEEP_INTERVAL_MS);
}
