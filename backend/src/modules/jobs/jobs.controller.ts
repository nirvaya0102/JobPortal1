import { Request, Response } from "express";
import { JobStatus, Prisma } from "@prisma/client";
import prisma from "../../lib/prisma";
import {
  createJobService,
  getJobByIdService,
  applyToJobService,
  getJobApplicantsService,
} from "./jobs.service";
import { validateBody } from "../../utils/validate";
import {
  createJobSchema,
  applyToJobSchema,
} from "../../validations/job.validation";
import {
  getPagination,
  getSorting,
  getPaginationMeta,
} from "../../utils/pagination";
import { asyncHandler } from "../../utils/asyncHandler";
import { sendSuccess } from "../../utils/ApiResponse";
import { AppError } from "../../utils/AppError";
import { uploadToCloudinary } from "../../utils/cloudinary";
import { generateSignedResumeUrl } from "../../utils/cloudinary";
import { generateSignedResumeDownloadUrl } from "../../utils/cloudinary";
import { updateApplicationStatusService } from "./jobs.service";
 





export const createJob = asyncHandler(async (req: any, res: Response) => {
  const validatedData = validateBody(createJobSchema, {
    ...req.body,
    salaryMin:
      req.body.salaryMin !== undefined && req.body.salaryMin !== ""
        ? Number(req.body.salaryMin)
        : null,
    salaryMax:
      req.body.salaryMax !== undefined && req.body.salaryMax !== ""
        ? Number(req.body.salaryMax)
        : null,
  });

  const job = await createJobService(validatedData, req.user.userId);

  return sendSuccess({
    res,
    statusCode: 201,
    message: "Job created successfully",
    data: { job },
  });
});

export const getAllJobs = asyncHandler(async (req: Request, res: Response) => {
  const { page, limit, skip } = getPagination(req.query);

  const search = typeof req.query.search === "string" ? req.query.search.trim() : "";
  const location =
    typeof req.query.location === "string" ? req.query.location.trim() : "";
  const jobType =
    typeof req.query.jobType === "string" ? req.query.jobType.trim() : "";
  const requestedStatus =
    typeof req.query.status === "string" ? req.query.status.trim() : "OPEN";
  const status = Object.values(JobStatus).includes(requestedStatus as JobStatus)
    ? (requestedStatus as JobStatus)
    : requestedStatus === "ALL"
      ? "ALL"
      : JobStatus.OPEN;
  const salaryMin =
    req.query.salaryMin !== undefined && req.query.salaryMin !== ""
      ? Number(req.query.salaryMin)
      : null;
  const salaryMax =
    req.query.salaryMax !== undefined && req.query.salaryMax !== ""
      ? Number(req.query.salaryMax)
      : null;
  const sortBy = typeof req.query.sortBy === "string" ? req.query.sortBy : "createdAt";
  const sortOrder = req.query.sortOrder === "asc" ? "asc" : "desc";

  const filters: Prisma.JobWhereInput[] = [];

  if (status !== "ALL") {
    filters.push({ status });
  }

  if (search) {
    filters.push({
      OR: [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { location: { contains: search, mode: "insensitive" } },
        { jobType: { contains: search, mode: "insensitive" } },
        { company: { name: { contains: search, mode: "insensitive" } } },
      ],
    });
  }

  if (location) {
    filters.push({
      location: { contains: location, mode: "insensitive" },
    });
  }

  if (jobType) {
    filters.push({
      jobType: { equals: jobType, mode: "insensitive" },
    });
  }

  if (salaryMin !== null && !Number.isNaN(salaryMin)) {
    filters.push({
      OR: [{ salaryMax: { gte: salaryMin } }, { salaryMax: null }],
    });
  }

  if (salaryMax !== null && !Number.isNaN(salaryMax)) {
    filters.push({
      OR: [{ salaryMin: { lte: salaryMax } }, { salaryMin: null }],
    });
  }

  const where: Prisma.JobWhereInput = filters.length ? { AND: filters } : {};

  const orderBy: Prisma.JobOrderByWithRelationInput =
    sortBy === "applicantsCount" || sortBy === "applications"
      ? { applications: { _count: sortOrder } }
      : getSorting(
          { sortBy, sortOrder },
          ["createdAt", "title", "location", "jobType", "salaryMin", "salaryMax"],
          "createdAt"
        );

  const [jobs, total] = await Promise.all([
    prisma.job.findMany({
      where,
      skip,
      take: limit,
      orderBy,
      include: {
        company: true,
        _count: {
          select: { applications: true },
        },
      },
    }),
    prisma.job.count({ where }),
  ]);

  return sendSuccess({
    res,
    message: "Jobs retrieved successfully",
    data: {
      jobs,
      pagination: getPaginationMeta(total, page, limit),
    },
  });
});

export const getMyJobs = asyncHandler(async (req: any, res: Response) => {
  const { page, limit, skip } = getPagination(req.query);

  const orderBy = getSorting(
    req.query,
    ["createdAt", "title", "location", "jobType"],
    "createdAt"
  );

  const where = {
    createdById: req.user.userId,
  };

  const [jobs, total] = await Promise.all([
    prisma.job.findMany({
      where,
      skip,
      take: limit,
      orderBy,
      include: {
        company: true,
        _count: {
          select: { applications: true },
        },
      },
    }),
    prisma.job.count({ where }),
  ]);

  return sendSuccess({
    res,
    message: "My jobs retrieved successfully",
    data: {
      jobs,
      pagination: getPaginationMeta(total, page, limit),
    },
  });
});

export const getJobById = asyncHandler(async (req: Request, res: Response) => {
  const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

  const job = await getJobByIdService(id);

  if (!job) {
    throw new AppError("Job not found", 404);
  }

  return sendSuccess({
    res,
    message: "Job retrieved successfully",
    data: { job },
  });
});

export const applyToJob = asyncHandler(async (req: any, res: Response) => {
  const file = req.file;

  const validatedData = validateBody(applyToJobSchema, {
    email: req.body.email,
    phone: req.body.phone,
    coverLetter: req.body.coverLetter,
  });

  let uploadedResume: { url?: string; publicId?: string } | null = null;

  if (file) {
    uploadedResume = await uploadToCloudinary(file);
  }

  const application = await applyToJobService(
    req.params.jobId,
    req.user.userId,
    {
      applicantEmail: validatedData.email,
      applicantPhone: validatedData.phone,
      coverLetter: validatedData.coverLetter,
      resumeUrl: uploadedResume?.url || null,
      resumePublicId: uploadedResume?.publicId || null,
      resumeFileName: file?.originalname || null,
      resumeFileType: file?.mimetype || null,
    }
  );

  return sendSuccess({
    res,
    statusCode: 201,
    message: "Application submitted successfully",
    data: { application },
  });
});

export const getMyApplications = asyncHandler(
  async (req: any, res: Response) => {
    const { page, limit, skip } = getPagination(req.query);

    const orderBy = getSorting(
      req.query,
      ["appliedAt", "status"],
      "appliedAt"
    );

    const where = {
      candidateId: req.user.userId,
    };

    const [applications, total] = await Promise.all([
      prisma.application.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          job: {
            include: {
              company: true,
            },
          },
        },
      }),
      prisma.application.count({ where }),
    ]);

    return sendSuccess({
      res,
      message: "Applications retrieved successfully",
      data: {
        applications,
        pagination: getPaginationMeta(total, page, limit),
      },
    });
  }
);

export const getJobApplicants = asyncHandler(
  async (req: any, res: Response) => {
    const applicants = await getJobApplicantsService(
      req.params.jobId,
      req.user.userId
    );

    return sendSuccess({
      res,
      message: "Job applicants retrieved successfully",
      data: { applicants },
    });
  }
);

export const getApplicationResume = asyncHandler(
  async (req: any, res: Response) => {
    const { jobId, applicationId } = req.params;
    

    const application = await prisma.application.findFirst({
      where: {
        id: applicationId,
        jobId,
        job: {
          createdById: req.user.userId,
        },
      },
      select: {
        resumePublicId: true,
        resumeFileName: true,
      },
    });

    if (!application) {
      throw new AppError("Application not found or unauthorized", 404);
    }

    if (!application.resumePublicId) {
      throw new AppError("Resume not found", 400);
    }

    const url = generateSignedResumeDownloadUrl(application.resumePublicId);
    

    return sendSuccess({
      res,
      message: "Resume URL generated successfully",
      data: {
        url,
        fileName: application.resumeFileName,
      },
    });
  }
);

export const updateApplicationStatus = asyncHandler(
  async (req: any, res: Response) => {
    const { jobId, applicationId } = req.params;
    const { status } = req.body;

    const application = await updateApplicationStatusService(
      jobId,
      applicationId,
      req.user.userId,
      status
    );

    return sendSuccess({
      res,
      message: "Application status updated successfully",
      data: { application },
    });
  }
);
