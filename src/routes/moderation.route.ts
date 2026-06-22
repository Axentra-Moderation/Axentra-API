import { Router } from "express";
import { banUser } from "../controllers/moderation/ban.controller";
import { unbanUser } from "../controllers/moderation/unban.controller";
import { kickUser } from "../controllers/moderation/kick.controller";

const router = Router();

router.put("/:guildId/moderation/ban/:userId", banUser);
router.delete("/:guildId/moderation/ban/:userId", unbanUser);
router.delete("/:guildId/moderation/kick/:userId", kickUser);

export default router;
