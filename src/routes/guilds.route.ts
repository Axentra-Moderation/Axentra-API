import { Router } from "express";
import { updateGuildSettings } from "../controllers/guilds/updateGuildSettings.controller";
import { getGuildSettings } from "../controllers/guilds/getGuildSettings.controller";

const router = Router();

router.get("/:guildId", getGuildSettings);
router.post("/:guildId", updateGuildSettings);

export default router;
