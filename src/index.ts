import "dotenv/config";
import { createApp } from "./app";
import { logger } from "./utils/logger";
import { startBanExpirySweeper } from "./jobs/ban.expiry.sweeper";

logger.info("Starting");

const PORT = process.env.PORT ?? 3000;

process.on("uncaughtException", (err) => {
  console.error("Uncaught exception:", err);
  process.exit(1);
});

process.on("unhandledRejection", (err) => {
  console.error("Unhandled rejection:", err);
  process.exit(1);
});

const required = ["DATABASE_URL", "JWT_SECRET"];
for (const key of required) {
  if (!process.env[key]) throw new Error(`Missing required env var: ${key}`);
}

createApp().listen(PORT, () => {
  logger.info(`API listening on port ${PORT}`);
});

startBanExpirySweeper;
