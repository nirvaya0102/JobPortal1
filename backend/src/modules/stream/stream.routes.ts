import { Router } from "express";
import { authMiddleware } from "../../middleware/auth.middleware";
import { authorizeRoles } from "../../middleware/authorize.middleware";
import { createStreamChannel, getStreamToken } from "./stream.controller";

const router = Router();

router.get(
  "/token",
  authMiddleware,
  authorizeRoles("CANDIDATE", "EMPLOYER", "ADMIN"),
  getStreamToken
);

router.post(
  "/channel",
  authMiddleware,
  authorizeRoles("CANDIDATE", "EMPLOYER", "ADMIN"),
  createStreamChannel
);

export default router;
