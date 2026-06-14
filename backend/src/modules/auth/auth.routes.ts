import { Router } from "express";

import {
  deleteCandidateResume,
  getMe,
  login,
  register,
  forgotPassword,
  resetPassword,
  verifyEmail,
  resendVerificationEmail,
  refreshToken,
  updateCandidateProfile,
  updateFcmToken,
  uploadCandidateResume,
} from "./auth.controller";

import { authMiddleware } from "../../middleware/auth.middleware";
import { loginRateLimiter } from "../../middleware/rateLimit.middleware";
import { authorizeRoles } from "../../middleware/authorize.middleware";
import { validate } from "../../middleware/validate.middleware";
import { resumeUpload } from "../../middleware/upload.middleware";
import {
  loginSchema,
  registerSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  resendVerificationSchema,
  updateCandidateProfileSchema,
} from "../../validations/auth.validation";

const router = Router();

router.post("/register", validate(registerSchema), register);

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
  "/profile",
  authMiddleware,
  authorizeRoles("CANDIDATE"),
  validate(updateCandidateProfileSchema),
  updateCandidateProfile
);

router.post(
  "/profile/resume",
  authMiddleware,
  authorizeRoles("CANDIDATE"),
  resumeUpload.single("resume"),
  uploadCandidateResume
);

router.delete(
  "/profile/resume",
  authMiddleware,
  authorizeRoles("CANDIDATE"),
  deleteCandidateResume
);

router.patch(
  "/fcm-token",
  authMiddleware,
  updateFcmToken
);

export default router;
