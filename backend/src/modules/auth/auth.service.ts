import bcrypt from "bcrypt";
import crypto from "crypto";
import prisma from "../../lib/prisma";
import {
  generateAccessToken,
  generateRefreshToken,
  verifyToken,
} from "../../lib/jwt";
import { sendEmail } from "../../utils/email";
import { AppError } from "../../utils/AppError";
import { USER_ROLES, TOKEN_EXPIRY } from "../../constants";

const FRONTEND_URL = process.env.FRONTEND_URL || "http://localhost:3000";

type CandidateProfileInput = {
  headline?: string;
  bio?: string;
  skills?: string;
  location?: string;
};

type ResumeUploadInput = {
  resumeUrl: string;
  resumeFileName: string;
  resumeFileType: string;
};

const safeUserSelect = {
  id: true,
  name: true,
  email: true,
  phone: true,
  location: true,
  role: true,
  createdAt: true,
  emailVerified: true,
  fcmToken: true,
  companyId: true,
  company: true,
  candidateProfile: true,
};

function createSecureToken() {
  return crypto.randomBytes(32).toString("hex");
}

export const registerUser = async (data: any) => {
  const {
    name,
    email,
    phone,
    password,
    role,
    companyName,
    companyLocation,
    companyDescription,
    companyWebsite,
    adminRegistrationCode,
  } = data;

  if (![USER_ROLES.CANDIDATE, USER_ROLES.EMPLOYER, USER_ROLES.ADMIN].includes(role)) {
    throw new AppError("Invalid role", 400);
  }

  if (role === USER_ROLES.ADMIN) {
    const expectedCode = process.env.ADMIN_REGISTRATION_CODE;

    if (!expectedCode || adminRegistrationCode !== expectedCode) {
      throw new AppError("Invalid admin registration code", 403);
    }
  }

  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  if (existingUser) {
    throw new AppError("User already exists", 409);
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const emailVerificationToken = createSecureToken();
  const emailVerificationExpires = new Date(
    Date.now() + TOKEN_EXPIRY.EMAIL_VERIFICATION_MS
  );

  let user;

  if (role === USER_ROLES.EMPLOYER) {
    if (!companyName || !companyLocation) {
      throw new AppError("Company name and location are required", 400);
    }

    const company = await prisma.company.create({
      data: {
        name: companyName,
        location: companyLocation,
        description: companyDescription || null,
        website: companyWebsite || null,
      },
    });

    user = await prisma.user.create({
      data: {
        name,
        email,
        phone: phone || null,
        password: hashedPassword,
        role,
        companyId: company.id,
        emailVerified: false,
        emailVerificationToken,
        emailVerificationExpires,
      },
      include: {
        company: true,
        candidateProfile: true,
      },
    });
  } else if (role === USER_ROLES.CANDIDATE) {
    user = await prisma.user.create({
      data: {
        name,
        email,
        phone: phone || null,
        password: hashedPassword,
        role,
        emailVerified: false,
        emailVerificationToken,
        emailVerificationExpires,
        candidateProfile: {
          create: {
            headline: "",
            bio: "",
            skills: "",
            resumeUrl: null,
          },
        },
      },
      include: {
        company: true,
        candidateProfile: true,
      },
    });
  } else {
    user = await prisma.user.create({
      data: {
        name,
        email,
        phone: phone || null,
        password: hashedPassword,
        role,
        emailVerified: false,
        emailVerificationToken,
        emailVerificationExpires,
      },
      include: {
        company: true,
        candidateProfile: true,
      },
    });
  }

  const verifyLink = `${FRONTEND_URL}/verify-email/${emailVerificationToken}`;

  await sendEmail({
    to: email,
    subject: "Verify your email",
    text: `Click this link to verify your email: ${verifyLink}`,
  });

  const {
    password: _password,
    refreshToken,
    emailVerificationToken: _emailVerificationToken,
    emailVerificationExpires: _emailVerificationExpires,
    passwordResetToken: _passwordResetToken,
    passwordResetExpires: _passwordResetExpires,
    ...safeUser
  } = user;

  return safeUser;
};

export const loginUser = async (data: any) => {
  const { email, password } = data;

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    throw new AppError("Invalid credentials", 401);
  }

  const isPasswordValid = await bcrypt.compare(password, user.password);

  if (!isPasswordValid) {
    throw new AppError("Invalid credentials", 401);
  }

  const accessToken = generateAccessToken({
    userId: user.id,
    role: user.role,
  });

  const refreshToken = generateRefreshToken({
    userId: user.id,
  });

  await prisma.user.update({
    where: { id: user.id },
    data: { refreshToken },
  });

  const {
    password: _,
    refreshToken: __,
    emailVerificationToken,
    emailVerificationExpires,
    passwordResetToken,
    passwordResetExpires,
    ...safeUser
  } = user;

  return {
    user: safeUser,
    accessToken,
    refreshToken,
  };
};

export const forgotPasswordService = async (email: string) => {
  if (!email) {
    throw new AppError("Email is required", 400);
  }

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    return {
      message: "If an account exists, reset link has been sent.",
    };
  }

  const passwordResetToken = createSecureToken();
  const passwordResetExpires = new Date(
    Date.now() + TOKEN_EXPIRY.PASSWORD_RESET_MS
  );

  await prisma.user.update({
    where: { email },
    data: {
      passwordResetToken,
      passwordResetExpires,
    },
  });

  const resetLink = `${FRONTEND_URL}/reset-password/${passwordResetToken}`;

  await sendEmail({
    to: email,
    subject: "Reset your password",
    text: `Click this link to reset your password: ${resetLink}`,
  });

  return {
    message: "If an account exists, reset link has been sent.",
  };
};

export const resetPasswordService = async (
  token: string,
  password: string
) => {
  if (!token) {
    throw new AppError("Reset token is required", 400);
  }

  if (!password || password.length < 8) {
    throw new AppError("Password must be at least 8 characters", 400);
  }

  const user = await prisma.user.findFirst({
    where: {
      passwordResetToken: token,
      passwordResetExpires: {
        gt: new Date(),
      },
    },
  });

  if (!user) {
    throw new AppError("Invalid or expired reset token", 400);
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      password: hashedPassword,
      passwordResetToken: null,
      passwordResetExpires: null,
      refreshToken: null,
    },
  });

  return {
    message: "Password updated successfully",
  };
};

export const verifyEmailService = async (token: string) => {
  if (!token) {
    throw new AppError("Verification token is required", 400);
  }

  const user = await prisma.user.findFirst({
    where: {
      emailVerificationToken: token,
      emailVerificationExpires: {
        gt: new Date(),
      },
    },
  });

  if (!user) {
    throw new AppError("Invalid or expired verification token", 400);
  }

  await prisma.user.update({
    where: { id: user.id },
    data: {
      emailVerified: true,
      emailVerificationToken: null,
      emailVerificationExpires: null,
    },
  });

  return {
    message: "Email verified successfully",
  };
};

export const resendVerificationEmailService = async (email: string) => {
  if (!email) {
    throw new AppError("Email is required", 400);
  }

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    return {
      message: "If account exists, verification email has been sent.",
    };
  }

  if (user.emailVerified) {
    throw new AppError("Email is already verified", 400);
  }

  const emailVerificationToken = createSecureToken();
  const emailVerificationExpires = new Date(
    Date.now() + TOKEN_EXPIRY.EMAIL_VERIFICATION_MS
  );

  await prisma.user.update({
    where: { email },
    data: {
      emailVerificationToken,
      emailVerificationExpires,
    },
  });

  const verifyLink = `${FRONTEND_URL}/verify-email/${emailVerificationToken}`;

  await sendEmail({
    to: email,
    subject: "Verify your email",
    text: `Click this link to verify your email: ${verifyLink}`,
  });

  return {
    message: "Verification email sent",
  };
};

export const refreshTokenService = async (token: string) => {
  if (!token) {
    throw new AppError("Refresh token is required", 401);
  }

  const decoded = verifyToken(token) as {
    userId?: string;
  };

  if (!decoded.userId) {
    throw new AppError("Invalid refresh token", 401);
  }

  const user = await prisma.user.findUnique({
    where: { id: decoded.userId },
  });

  if (!user || user.refreshToken !== token) {
    throw new AppError("Invalid refresh token", 401);
  }

  const accessToken = generateAccessToken({
    userId: user.id,
    role: user.role,
  });

  return {
    accessToken,
    refreshToken: token,
  };
};

export const getAuthenticatedUserService = async (userId: string) => {
  if (!userId) {
    throw new AppError("Unauthorized", 401);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: safeUserSelect,
  });

  if (!user) {
    throw new AppError("User not found", 404);
  }

  return user;
};

export const updateCandidateProfileService = async (
  userId: string,
  data: CandidateProfileInput
) => {
  if (!userId) {
    throw new AppError("Unauthorized", 401);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      role: true,
    },
  });

  if (!user) {
    throw new AppError("User not found", 404);
  }

  if (user.role !== USER_ROLES.CANDIDATE) {
    throw new AppError("Only candidates can update candidate profiles", 403);
  }

  const { location, headline, bio, skills } = data;

  await prisma.$transaction(async (tx) => {
    if (location !== undefined) {
      await tx.user.update({
        where: { id: userId },
        data: { location },
      });
    }

    await tx.candidateProfile.upsert({
      where: { userId },
      create: {
        userId,
        headline: headline ?? "",
        bio: bio ?? "",
        skills: skills ?? "",
      },
      update: {
        ...(headline !== undefined && { headline }),
        ...(bio !== undefined && { bio }),
        ...(skills !== undefined && { skills }),
      },
    });
  });

  return getAuthenticatedUserService(userId);
};

export const uploadCandidateResumeService = async (
  userId: string,
  data: ResumeUploadInput
) => {
  if (!userId) {
    throw new AppError("Unauthorized", 401);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      role: true,
    },
  });

  if (!user) {
    throw new AppError("User not found", 404);
  }

  if (user.role !== USER_ROLES.CANDIDATE) {
    throw new AppError("Only candidates can upload resumes", 403);
  }

  return prisma.candidateProfile.upsert({
    where: { userId },
    create: {
      userId,
      headline: "",
      bio: "",
      skills: "",
      resumeUrl: data.resumeUrl,
      resumeFileName: data.resumeFileName,
      resumeFileType: data.resumeFileType,
    },
    update: {
      resumeUrl: data.resumeUrl,
      resumeFileName: data.resumeFileName,
      resumeFileType: data.resumeFileType,
    },
  });
};

export const deleteCandidateResumeService = async (userId: string) => {
  if (!userId) {
    throw new AppError("Unauthorized", 401);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      role: true,
    },
  });

  if (!user) {
    throw new AppError("User not found", 404);
  }

  if (user.role !== USER_ROLES.CANDIDATE) {
    throw new AppError("Only candidates can delete resumes", 403);
  }

  return prisma.candidateProfile.upsert({
    where: { userId },
    create: {
      userId,
      headline: "",
      bio: "",
      skills: "",
      resumeUrl: null,
      resumeFileName: null,
      resumeFileType: null,
    },
    update: {
      resumeUrl: null,
      resumeFileName: null,
      resumeFileType: null,
    },
  });
};

export const logoutUserService = async (userId: string) => {
  if (!userId) {
    throw new AppError("User ID is required", 400);
  }

  await prisma.user.update({
    where: { id: userId },
    data: {
      refreshToken: null,
    },
  });

  return {
    message: "Logout successful",
  };
};
