import { Router } from "express";
import { getNotifications, markAsRead, createDemoNotifications } from "./notification.controller";
import { authMiddleware } from "../../middleware/auth.middleware";

const router = Router();

router.use(authMiddleware as any);

router.get("/", getNotifications);
router.post("/demo", createDemoNotifications);
router.put("/:id/read", markAsRead);

export default router;
