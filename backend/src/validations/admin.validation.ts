import { z } from "zod";

export const rejectJobSchema = z.object({
  rejectionReason: z
    .string()
    .trim()
    .max(500, "Rejection reason must be 500 characters or less")
    .optional()
    .nullable(),
});
