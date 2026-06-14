import { Request, Response } from "express";
import prisma from "../../lib/prisma";
import {
  deleteCandidateResumeService,
  forgotPasswordService,
  getAuthenticatedUserService,
  loginUser,
  registerUser,
  refreshTokenService,
  resendVerificationEmailService,
  resetPasswordService,
  updateCandidateProfileService,
  uploadCandidateResumeService,
  verifyEmailService,
} from "./auth.service";

import { asyncHandler } from "../../utils/asyncHandler";
import { AppError } from "../../utils/AppError";
import { sendSuccess } from "../../utils/ApiResponse";
import { COOKIE_NAMES } from "../../constants";
import { uploadToCloudinary } from "../../utils/cloudinary";


const getSingleString = (value: unknown): string | undefined => {
  if (typeof value === "string") return value;
  if (Array.isArray(value)) return value[0];
  return undefined;
};


export const register = asyncHandler(async (req: Request, res: Response) => {
  const user = await registerUser(req.body);

  return sendSuccess({
    res,
    statusCode: 201,
    message: "User registered successfully",
    data: {
      user,
    },
  });
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  const result = await loginUser(req.body);

  // WEB COOKIES
  res.cookie(COOKIE_NAMES.ACCESS_TOKEN, result.accessToken, {
    httpOnly: true,
    secure: false,
    sameSite: "lax",
    maxAge: 15 * 60 * 1000,
  });

  res.cookie(COOKIE_NAMES.REFRESH_TOKEN, result.refreshToken, {
    httpOnly: true,
    secure: false,
    sameSite: "lax",
    maxAge: 7 * 24 * 60 * 60 * 1000,
  });

  // MOBILE CHECK
  const userAgent = req.headers["user-agent"]?.toLowerCase() || "";
  const isMobile = 
    req.headers["x-client-type"] === "mobile" || 
    userAgent.includes("dart") || 
    userAgent.includes("flutter");

  return sendSuccess({
    res,
    message: "Login successful",
    data: {
      user: result.user,

      // SEND TOKENS ONLY FOR MOBILE
      ...(isMobile && {
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      }),
    },
  });
});

export const forgotPassword = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await forgotPasswordService(req.body.email);

    return sendSuccess({
      res,
      message: result.message,
    });
  }
);

export const resetPassword = asyncHandler(
  async (req: Request, res: Response) => {
    const token = getSingleString(req.params.token);

    if (!token) {
      throw new AppError("Reset token is required", 400);
    }

    const result = await resetPasswordService(
      token,
      req.body.password
    );

    return sendSuccess({
      res,
      message: result.message,
    });
  }
);
export const resendVerificationEmail = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await resendVerificationEmailService(req.body.email);

    return sendSuccess({
      res,
      message: result.message,
    });
  }
);

export const verifyEmail = asyncHandler(
  async (req: Request, res: Response) => {
    const token = getSingleString(req.params.token);

    if (!token) {
      throw new AppError("Verification token is required", 400);
    }

    const result = await verifyEmailService(token);

    return sendSuccess({
      res,
      message: result.message,
    });
  }
);

export const getMe = asyncHandler(async (req: any, res: Response) => {
  const userId = req.user?.userId;

  const user = await getAuthenticatedUserService(userId);

  return sendSuccess({
    res,
    message: "Authenticated user retrieved successfully",
    data: {
      user,
    },
  });
});

export const updateCandidateProfile = asyncHandler(
  async (req: any, res: Response) => {
    const profile = await updateCandidateProfileService(
      req.user?.userId,
      req.body
    );

    return sendSuccess({
      res,
      message: "Profile updated successfully",
      data: {
        profile,
      },
    });
  }
);

export const uploadCandidateResume = asyncHandler(
  async (req: any, res: Response) => {
    const file = req.file as Express.Multer.File | undefined;

    if (!file) {
      throw new AppError("Resume file is required", 400);
    }

    const uploadedResume = await uploadToCloudinary(
      file,
      "jobportal/candidate-profiles/resumes"
    );

    const profile = await uploadCandidateResumeService(req.user?.userId, {
      resumeUrl: uploadedResume.url,
      resumeFileName: file.originalname,
      resumeFileType: file.mimetype,
    });

    return sendSuccess({
      res,
      message: "Resume uploaded successfully",
      data: {
        profile,
      },
    });
  }
);

export const deleteCandidateResume = asyncHandler(
  async (req: any, res: Response) => {
    const profile = await deleteCandidateResumeService(req.user?.userId);

    return sendSuccess({
      res,
      message: "Resume removed successfully",
      data: {
        profile,
      },
    });
  }
);

export const refreshToken = asyncHandler(
  async (req: Request, res: Response) => {

    const userAgent = req.headers["user-agent"]?.toLowerCase() || "";
    const isMobile = 
      req.headers["x-client-type"] === "mobile" || 
      userAgent.includes("dart") || 
      userAgent.includes("flutter");

    // WEB -> COOKIE
    // MOBILE -> BODY
    const token = isMobile
      ? req.body.refreshToken
      : req.cookies?.[COOKIE_NAMES.REFRESH_TOKEN];

    if (!token) {
      throw new AppError("No refresh token", 401);
    }

    const result = await refreshTokenService(token);

    // UPDATE WEB COOKIE
    res.cookie(COOKIE_NAMES.ACCESS_TOKEN, result.accessToken, {
      httpOnly: true,
      secure: false,
      sameSite: "lax",
      maxAge: 15 * 60 * 1000,
    });

    return sendSuccess({
      res,
      message: "Session refreshed successfully",
      data: {

        // MOBILE RESPONSE
        ...(isMobile && {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        }),
      },
    });
  }
);

export const updateFcmToken = asyncHandler(async (req: any, res: Response) => {
  const { fcmToken } = req.body;
  
  if (fcmToken) {
    await prisma.user.update({
      where: { id: req.user.userId },
      data: { fcmToken },
    });
  }

  return sendSuccess({
    res,
    message: "FCM token updated successfully",
  });
});
