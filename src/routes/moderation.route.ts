import { Router } from "express";
import { banUser } from "../controllers/moderation/ban/ban.controller";
import { unbanUser } from "../controllers/moderation/ban/unban.controller";
import { kickUser } from "../controllers/moderation/kick/kick.controller";
import { muteUser } from "../controllers/moderation/mute/mute.controller";
import { unmuteUser } from "../controllers/moderation/mute/unmute.controller";

const router = Router();

router.put("/:guildId/moderation/ban/:userId", banUser);
router.delete("/:guildId/moderation/ban/:userId", unbanUser);
router.delete("/:guildId/moderation/kick/:userId", kickUser);
router.put("/:guildId/moderation/mute/:userId", muteUser);
router.delete("/:guildId/moderation/mute/:userId", unmuteUser);

export default router;
