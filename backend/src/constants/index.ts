export const USER_ROLES = {
  CANDIDATE: "CANDIDATE",
  EMPLOYER: "EMPLOYER",
  ADMIN: "ADMIN",
} as const;

export const JOB_STATUS = {
  PENDING: "PENDING",
  APPROVED: "APPROVED",
  REJECTED: "REJECTED",
  CLOSED: "CLOSED",
} as const;

export const APPLICATION_STATUS = {
  PENDING: "PENDING",
  REVIEWED: "REVIEWED",
  SHORTLISTED: "SHORTLISTED",
  REJECTED: "REJECTED",
} as const;

export const TOKEN_EXPIRY = {
  ACCESS_TOKEN: "15m",
  REFRESH_TOKEN: "7d",
  EMAIL_VERIFICATION_MS: 24 * 60 * 60 * 1000,
  PASSWORD_RESET_MS: 15 * 60 * 1000,
} as const;

export const COOKIE_NAMES = {
  ACCESS_TOKEN: "accessToken",
  REFRESH_TOKEN: "refreshToken",
} as const;
