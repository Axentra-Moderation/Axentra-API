import winston from "winston";
import DailyRotateFile from "winston-daily-rotate-file";

const { combine, timestamp, errors, splat, json, colorize, printf } =
  winston.format;

// Directory where rotating log files are written. Created automatically.
const LOG_DIR = process.env["LOG_DIR"] ?? "logs";

// Default level: verbose in dev, quieter in production. Override with LOG_LEVEL.
const LOG_LEVEL =
  process.env["LOG_LEVEL"] ??
  (process.env["NODE_ENV"] === "production" ? "info" : "debug");

// Shared base applied once at the logger level: timestamp, full error stacks,
// and %-style splat interpolation. Each transport then adds only its finalizer
// (json / printf) so splat is never processed twice.
const baseFormat = combine(timestamp(), errors({ stack: true }), splat());

// Structured JSON for files.
const fileFormat = json();

// Human-readable, colorized output for the terminal during development.
const consoleFormat = combine(
  colorize(),
  printf(({ level, message, timestamp: ts, stack, ...meta }) => {
    // Drop noise from defaultMeta in the console; keep call-site metadata.
    delete meta["service"];
    const rest = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : "";
    return `${String(ts)} ${level}: ${stack ?? message}${rest}`;
  }),
);

// All logs (info and above), rotated daily, kept 14 days, compressed once rotated.
const combinedFile = new DailyRotateFile({
  format: fileFormat,
  dirname: LOG_DIR,
  filename: "application-%DATE%.log",
  datePattern: "DD-MM-YYYY",
  zippedArchive: true,
  maxSize: "20m",
  maxFiles: "14d",
});

// Error-only stream, so on-call can tail a clean error feed.
const errorFile = new DailyRotateFile({
  level: "error",
  format: fileFormat,
  dirname: LOG_DIR,
  filename: "application-error-%DATE%.log",
  datePattern: "DD-MM-YYYY",
  zippedArchive: true,
  maxSize: "20m",
  maxFiles: "30d",
});

// Surface transport failures (e.g. disk full) instead of swallowing them.
for (const transport of [combinedFile, errorFile]) {
  transport.on("error", (err) => {
    console.error("winston transport error:", err);
  });
}

export const logger = winston.createLogger({
  level: LOG_LEVEL,
  format: baseFormat,
  defaultMeta: { service: "mod-api" },
  transports: [combinedFile, errorFile],
  // Log and survive uncaught errors rather than dying silently.
  exceptionHandlers: [
    new DailyRotateFile({
      format: fileFormat,
      dirname: LOG_DIR,
      filename: "exceptions-%DATE%.log",
      datePattern: "YYYY-MM-DD",
      zippedArchive: true,
      maxFiles: "30d",
    }),
  ],
  rejectionHandlers: [
    new DailyRotateFile({
      format: fileFormat,
      dirname: LOG_DIR,
      filename: "rejections-%DATE%.log",
      datePattern: "YYYY-MM-DD",
      zippedArchive: true,
      maxFiles: "30d",
    }),
  ],
  exitOnError: false,
});

// In non-production, also print to the console with the readable format.
if (process.env["NODE_ENV"] !== "production") {
  logger.add(new winston.transports.Console({ format: consoleFormat }));
}
