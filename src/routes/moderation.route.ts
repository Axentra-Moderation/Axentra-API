import { Router } from "express";
import { banUser } from "../controllers/moderation/ban.controller";
import { unbanUser } from "../controllers/moderation/unban.controller";

const router = Router();

router.put("/:guildId/moderation/ban/:userId", banUser);
router.delete("/:guildId/moderation/ban/:userId", unbanUser);

export default router;
