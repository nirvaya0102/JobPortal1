import { z } from "zod";

const cleanString = z
  .string()
  .trim()
  .min(1, "Field is required");

export const registerSchema = z.object({
  name: cleanString
    .min(2, "Name must be at least 2 characters")
    .max(50, "Name must be less than 50 characters"),

  email: z
    .string()
    .trim()
    .toLowerCase()
    .email("Invalid email address"),

  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .max(100, "Password is too long"),

  role: z.enum(["CANDIDATE", "EMPLOYER"]),

  companyName: z.string().trim().optional(),
  companyLocation: z.string().trim().optional(),
  companyDescription: z.string().trim().optional(),
  companyWebsite: z.string().trim().url("Invalid website URL").optional(),
});

export const loginSchema = z.object({
  email: z
    .string()
    .trim()
    .toLowerCase()
    .email("Invalid email address"),

  password: z.string().min(1, "Password is required"),
});

export const forgotPasswordSchema = z.object({
  email: z
    .string()
    .trim()
    .toLowerCase()
    .email("Invalid email address"),
});

export const resetPasswordSchema = z.object({
  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .max(100, "Password is too long"),
});

export const resendVerificationSchema = z.object({
  email: z
    .string()
    .trim()
    .toLowerCase()
    .email("Invalid email address"),
});

