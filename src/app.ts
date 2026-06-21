import "dotenv/config";
import express from "express";
import helmet from "helmet";
//import cors from "cors";
import authRouter from "./routes/auth.route";
import guildsRouter from "./routes/guilds.route";
import moderationRouter from "./routes/moderation.route";
//import { logsRouter } from "./routes/logs";
//import { warningsRouter } from "./routes/warnings";
//import { permissionsRouter } from "./routes/permissions";
import { auth } from "./middleware/auth";
//import { errorHandler } from "./middleware/errorHandler";

export function createApp() {
  const app = express();

  // Global middleware
  app.use(helmet());
  //app.use(cors({ origin: process.env.DASHBOARD_URL }));
  app.use(express.json());

  // Public routes (no auth required)
  app.use("/auth", authRouter);

  // Protected routes
  app.use(auth); // Resolve caller identity
  app.use("/guilds", guildsRouter);
  app.use("/guilds", moderationRouter);
  //app.use("/guilds", logsRouter);
  //app.use("/guilds", warningsRouter);
  //app.use("/guilds", permissionsRouter);

  //app.use(errorHandler);

  return app;
}
