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

function createSecureToken() {
  return crypto.randomBytes(32).toString("hex");
}

export const registerUser = async (data: any) => {
  const {
    name,
    email,
    password,
    role,
    companyName,
    companyLocation,
    companyDescription,
    companyWebsite,
  } = data;

  if (![USER_ROLES.CANDIDATE, USER_ROLES.EMPLOYER].includes(role)) {
    throw new AppError("Invalid role", 400);
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
        password: hashedPassword,
        role,
        companyId: company.id,
        emailVerified: false,
        emailVerificationToken,
        emailVerificationExpires,
      },
    });
  } else {
    user = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
        role,
        emailVerified: false,
        emailVerificationToken,
        emailVerificationExpires,
      },
    });
  }

  const verifyLink = `${FRONTEND_URL}/verify-email/${emailVerificationToken}`;

  await sendEmail({
    to: email,
    subject: "Verify your email",
    text: `Click this link to verify your email: ${verifyLink}`,
  });

  const { password: _, refreshToken, ...safeUser } = user;

  return safeUser;
};

export const loginUser = async (data: any) => {
  const { email, password } = data;

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    console.log(`Login failed: User not found for email: ${email}`);
    throw new AppError("Invalid credentials", 401);
  }

  const isPasswordValid = await bcrypt.compare(password, user.password);

  if (!isPasswordValid) {
    console.log(`Login failed: Invalid password for email: ${email}`);
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

  const { password: _, refreshToken: __, ...safeUser } = user;

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
  };
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