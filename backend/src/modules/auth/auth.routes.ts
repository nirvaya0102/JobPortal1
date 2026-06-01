import { Router } from "express";

import {
  getMe,
  login,
  register,
  forgotPassword,
  resetPassword,
  verifyEmail,
  resendVerificationEmail,
  refreshToken,
  updateFcmToken,
} from "./auth.controller";

import { authMiddleware } from "../../middleware/auth.middleware";
import { loginRateLimiter } from "../../middleware/rateLimit.middleware";
import { authorizeRoles } from "../../middleware/authorize.middleware";
import { validate } from "../../middleware/validate.middleware";
import {
  loginSchema,
  registerSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  resendVerificationSchema,
} from "../../validations/auth.validation";

const router = Router();

router.post("/register", register);

router.post(
  "/login",
  loginRateLimiter,
    validate(loginSchema),
  login
);

router.post(
  "/forgot-password",
  validate(forgotPasswordSchema),
  forgotPassword
);

router.post(
  "/reset-password/:token",
  validate(resetPasswordSchema),
  resetPassword
);

router.post(
  "/verify-email/:token",
  verifyEmail
);

router.post(
  "/resend-verification",
  validate(resendVerificationSchema),
  resendVerificationEmail
);

router.post("/refresh", refreshToken);

router.get(
  "/me",
  authMiddleware,
  authorizeRoles(
    "CANDIDATE",
    "EMPLOYER",
    "ADMIN"
  ),
  getMe
);

router.patch(
  "/fcm-token",
  authMiddleware,
  updateFcmToken
);

export default router;