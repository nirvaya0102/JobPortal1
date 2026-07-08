import { Router } from "express";
import { authMiddleware } from "../../middleware/auth.middleware";
import { authorizeRoles } from "../../middleware/authorize.middleware";
import { validate } from "../../middleware/validate.middleware";
import { USER_ROLES } from "../../constants";
import {
  approveJob,
  closeJob,
  getAdminJobs,
  rejectJob,
} from "./admin.jobs.controller";
import { rejectJobSchema } from "../../validations/admin.validation";

const router = Router();

router.use(authMiddleware, authorizeRoles(USER_ROLES.ADMIN));

router.get("/", getAdminJobs);
router.patch("/:jobId/approve", approveJob);
router.patch("/:jobId/reject", validate(rejectJobSchema), rejectJob);
router.patch("/:jobId/close", closeJob);

export default router;
