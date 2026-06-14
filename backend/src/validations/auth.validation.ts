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

  phone: z
    .string()
    .trim()
    .min(7, "Phone number must be at least 7 digits")
    .max(20, "Phone number is too long")
    .optional(),

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

export const updateCandidateProfileSchema = z
  .object({
    headline: z
      .string()
      .trim()
      .max(100, "Headline must be less than 100 characters")
      .optional(),

    bio: z
      .string()
      .trim()
      .max(1000, "Bio must be less than 1000 characters")
      .optional(),

    skills: z.string().trim().optional(),

    location: z.string().trim().optional(),
  })
  .refine(
    (data) =>
      data.headline !== undefined ||
      data.bio !== undefined ||
      data.skills !== undefined ||
      data.location !== undefined,
    {
      message: "At least one profile field is required",
    }
  );

