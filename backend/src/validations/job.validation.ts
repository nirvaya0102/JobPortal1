import { z } from "zod";

export const createJobSchema = z.object({
  title: z.string().trim().min(3, "Job title is required"),
  description: z.string().trim().min(10, "Description must be at least 10 characters"),
  location: z.string().trim().min(2, "Location is required"),
  jobType: z.enum(["Full-time", "Part-time", "Remote"]),
  salaryMin: z.number().int().positive().nullable().optional(),
  salaryMax: z.number().int().positive().nullable().optional(),
}).refine(
  (data) => {
    if (data.salaryMin && data.salaryMax) {
      return data.salaryMin <= data.salaryMax;
    }

    return true;
  },
  {
    message: "Minimum salary cannot be greater than maximum salary",
    path: ["salaryMin"],
  }
);

export const applyToJobSchema = z.object({
  email: z.string().trim().toLowerCase().email("Valid email is required"),
  phone: z
    .string()
    .trim()
    .min(7, "Phone number is required")
    .max(20, "Phone number is too long"),
  coverLetter: z.string().trim().min(5, "Cover letter is required").optional(),
});
