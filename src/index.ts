console.log("Starting...");
import "dotenv/config";
import { createApp } from "./app";
import { logger } from "./utils/logger";

const PORT = process.env.PORT ?? 3000;

process.on("uncaughtException", (err) => {
  console.error("Uncaught exception:", err);
  process.exit(1);
});

process.on("unhandledRejection", (err) => {
  console.error("Unhandled rejection:", err);
  process.exit(1);
});

createApp().listen(PORT, () => {
  logger.info(`API listening on port ${PORT}`);
});
