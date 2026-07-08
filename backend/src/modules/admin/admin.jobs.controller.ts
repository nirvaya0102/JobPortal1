import { Request, Response } from "express";
import { JobStatus, Prisma } from "@prisma/client";
import prisma from "../../lib/prisma";
import { asyncHandler } from "../../utils/asyncHandler";
import { sendSuccess } from "../../utils/ApiResponse";
import { AppError } from "../../utils/AppError";
import {
  getPagination,
  getPaginationMeta,
  getSorting,
} from "../../utils/pagination";

const adminJobInclude = {
  company: true,
  createdBy: {
    select: {
      id: true,
      name: true,
      email: true,
    },
  },
  _count: {
    select: {
      applications: true,
    },
  },
} satisfies Prisma.JobInclude;

const formatAdminJob = (job: Prisma.JobGetPayload<{ include: typeof adminJobInclude }>) => ({
  id: job.id,
  title: job.title,
  companyName: job.company?.name,
  employer: {
    id: job.createdBy.id,
    name: job.createdBy.name,
    email: job.createdBy.email,
  },
  location: job.location,
  jobType: job.jobType,
  salaryMin: job.salaryMin,
  salaryMax: job.salaryMax,
  status: job.status,
  rejectionReason: job.rejectionReason,
  createdAt: job.createdAt,
  applicantsCount: job._count.applications,
});

const getValidStatus = (value: unknown): JobStatus | undefined => {
  if (typeof value !== "string") return undefined;
  return Object.values(JobStatus).includes(value as JobStatus)
    ? (value as JobStatus)
    : undefined;
};

export const getAdminJobs = asyncHandler(async (req: Request, res: Response) => {
  const { page, limit, skip } = getPagination(req.query);
  const status = getValidStatus(req.query.status);
  const search = typeof req.query.search === "string" ? req.query.search.trim() : "";

  const filters: Prisma.JobWhereInput[] = [];

  if (status) {
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
        { createdBy: { name: { contains: search, mode: "insensitive" } } },
        { createdBy: { email: { contains: search, mode: "insensitive" } } },
      ],
    });
  }

  const where: Prisma.JobWhereInput = filters.length ? { AND: filters } : {};

  const sortBy = typeof req.query.sortBy === "string" ? req.query.sortBy : "createdAt";
  const sortOrder = req.query.sortOrder === "asc" ? "asc" : "desc";

  const orderBy: Prisma.JobOrderByWithRelationInput =
    sortBy === "applicantsCount" || sortBy === "applications"
      ? { applications: { _count: sortOrder } }
      : getSorting(
          { sortBy, sortOrder },
          ["createdAt", "title", "location", "jobType", "salaryMin", "salaryMax", "status"],
          "createdAt"
        );

  const [jobs, total] = await Promise.all([
    prisma.job.findMany({
      where,
      skip,
      take: limit,
      orderBy,
      include: adminJobInclude,
    }),
    prisma.job.count({ where }),
  ]);

  return sendSuccess({
    res,
    message: "Admin jobs retrieved successfully",
    data: {
      jobs: jobs.map(formatAdminJob),
      pagination: getPaginationMeta(total, page, limit),
    },
  });
});

export const approveJob = asyncHandler(async (req: any, res: Response) => {
  const job = await prisma.job.findUnique({ where: { id: req.params.jobId } });

  if (!job) {
    throw new AppError("Job not found", 404);
  }

  const updatedJob = await prisma.job.update({
    where: { id: job.id },
    data: {
      status: JobStatus.APPROVED,
      approvedAt: new Date(),
      approvedById: req.user.userId,
      rejectedAt: null,
      rejectedById: null,
      rejectionReason: null,
    },
    include: adminJobInclude,
  });

  return sendSuccess({
    res,
    message: "Job approved successfully",
    data: { job: formatAdminJob(updatedJob) },
  });
});

export const rejectJob = asyncHandler(async (req: any, res: Response) => {
  const job = await prisma.job.findUnique({ where: { id: req.params.jobId } });

  if (!job) {
    throw new AppError("Job not found", 404);
  }

  const updatedJob = await prisma.job.update({
    where: { id: job.id },
    data: {
      status: JobStatus.REJECTED,
      rejectedAt: new Date(),
      rejectedById: req.user.userId,
      rejectionReason: req.body.rejectionReason || null,
      approvedAt: null,
      approvedById: null,
    },
    include: adminJobInclude,
  });

  return sendSuccess({
    res,
    message: "Job rejected successfully",
    data: { job: formatAdminJob(updatedJob) },
  });
});

export const closeJob = asyncHandler(async (req: any, res: Response) => {
  const job = await prisma.job.findUnique({ where: { id: req.params.jobId } });

  if (!job) {
    throw new AppError("Job not found", 404);
  }

  const updatedJob = await prisma.job.update({
    where: { id: job.id },
    data: {
      status: JobStatus.CLOSED,
    },
    include: adminJobInclude,
  });

  return sendSuccess({
    res,
    message: "Job closed successfully",
    data: { job: formatAdminJob(updatedJob) },
  });
});
