import { Router } from "express";
import { discordRedirect } from "../controllers/auth/discord.controller";
import { discordCallback } from "../controllers/auth/callback.controller";
import { refreshToken } from "../controllers/auth/refresh.controller";

const router = Router();

router.get("/discord", discordRedirect);
router.get("/callback", discordCallback);
router.post("/refresh", refreshToken);

export default router;
