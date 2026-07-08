import prisma from "../../lib/prisma";
import { ApplicationStatus, JobStatus } from "@prisma/client";
import { AppError } from "../../utils/AppError";
import { sendPushNotification } from "../../utils/firebase";

export const createJobService = async (data: any, userId: string) => {
    const {
        title,
        description,
        location,
        jobType,
        salaryMin,
        salaryMax,
    } = data;

    const count = await prisma.job.count();

    const jobCode = `JOB-${String(count + 1).padStart(3, "0")}`;

    const employer = await prisma.user.findUnique({
        where: { id: userId },
        include: { company: true },
    });

    if (!employer) {
        throw new Error("User not found");
    }

    if (!employer.companyId) {
        throw new Error("Employer is not linked to any company");
    }

    const job = await prisma.job.create({
        data: {
            title,
            description,
            location,
            jobType,
            salaryMin,
            salaryMax,
            status: JobStatus.PENDING,
            companyId: employer.companyId,
            createdById: employer.id,
            jobCode,
        },
    });

    return job;
};

export const getMyJobsService = async (userId: string) => {
    const jobs = await prisma.job.findMany({
        where: { createdById: userId },
        orderBy: { createdAt: "desc" },
    });

    return jobs;
};

export const getAllJobsService = async (query: any) => {
    const { keyword, location, jobType, minSalary, maxSalary } = query;

    return await prisma.job.findMany({
        where: {
            status: JobStatus.APPROVED,

            AND: [
                keyword
                    ? {
                        OR: [
                            { title: { contains: keyword, mode: "insensitive" } },
                            { description: { contains: keyword, mode: "insensitive" } },
                        ],
                    }
                    : {},

                location
                    ? {
                        location: { contains: location, mode: "insensitive" },
                    }
                    : {},

                jobType
                    ? {
                        jobType: jobType,
                    }
                    : {},

                minSalary
                    ? {
                        salaryMin: { gte: Number(minSalary) },
                    }
                    : {},

                maxSalary
                    ? {
                        salaryMax: { lte: Number(maxSalary) },
                    }
                    : {},
            ],
        },

        include: {
            company: true,
        },

        orderBy: {
            createdAt: "desc",
        },
    });
};
export const getJobByIdService = async (jobId: string) => {
    return await prisma.job.findFirst({
        where: {
            id: jobId,
            status: JobStatus.APPROVED,
        },
        include: {
            company: true,
        },
    });
};


export const getMyApplicationsService = async (userId: string) => {
    return await prisma.application.findMany({
        where: { candidateId: userId },
        include: {
            job: {
                include: {
                    company: true,
                },
            },
        },
        orderBy: {
            appliedAt: "desc",
        },
    });
};

export const applyToJobService = async (
    jobId: string,
    userId: string,
    data: any
) => {
    const job = await prisma.job.findUnique({
        where: { id: jobId },
        include: { createdBy: true }
    });

    if (!job) {
        throw new Error("Job not found");
    }

    if (job.status !== JobStatus.APPROVED) {
        throw new AppError("This job is not available for applications", 403);
    }

    // prevent duplicate apply
    const existing = await prisma.application.findUnique({
        where: {
            jobId_candidateId: {
                jobId,
                candidateId: userId,
            },
        },
    });

    if (existing) {
        throw new Error("You already applied to this job");
    }

   const application = await prisma.application.create({
  data: {
    jobId,
    candidateId: userId,
    applicantEmail: data?.applicantEmail,
    applicantPhone: data?.applicantPhone,
    coverLetter: data?.coverLetter,
    resumeUrl: data?.resumeUrl,
    resumeFileName: data?.resumeFileName,
    resumeFileType: data?.resumeFileType,
    resumePublicId: data.resumePublicId,
  },
});

  const candidate = await prisma.user.findUnique({ where: { id: userId } });

  // Notify Employer
  if (job.createdBy?.fcmToken) {
    sendPushNotification(
      job.createdBy.fcmToken,
      "New Applicant!",
      `${candidate?.name || 'Someone'} applied for your job: ${job.title}`,
      { type: "new_applicant", jobId }
    );
  }

  // Notify Candidate
  if (candidate?.fcmToken) {
    sendPushNotification(
      candidate.fcmToken,
      "Application Submitted",
      `You successfully applied for ${job.title}`,
      { type: "application_submitted", jobId }
    );
  }

    return application;
};

export const getJobApplicantsService = async (
    jobId: string,
    userId: string
) => {
    const job = await prisma.job.findUnique({
        where: { id: jobId },
    });

    if (!job) {
        throw new Error("Job not found");
    }

    if (job.createdById !== userId) {
        throw new Error("Unauthorized");
    }

    return await prisma.application.findMany({
        where: { jobId },
        include: {
            candidate: {
                select: {
                    id: true,
                    name: true,
                    email: true,
                    phone: true,
                    candidateProfile: {
                        select: {
                            resumeUrl: true,
                            resumeFileName: true,
                            resumeFileType: true,
                        },
                    },
                },
            },
        },
        orderBy: {
            appliedAt: "desc",
        },
    });
};

export const updateApplicationStatusService = async (
  jobId: string,
  applicationId: string,
  employerId: string,
  status: ApplicationStatus
) => {
  const application = await prisma.application.findFirst({
    where: {
      id: applicationId,
      jobId,
      job: {
        createdById: employerId,
      },
    },
  });

  if (!application) {
    throw new AppError("Application not found or unauthorized", 404);
  }

  const updatedApplication = await prisma.application.update({
    where: {
      id: applicationId,
    },
    data: {
      status,
    },
    include: {
      candidate: {
        select: {
          id: true,
          name: true,
          email: true,
          fcmToken: true,
        },
      },
      job: {
        select: {
          id: true,
          title: true,
        },
      },
    },
  });

  if (updatedApplication.candidate?.fcmToken) {
    sendPushNotification(
      updatedApplication.candidate.fcmToken,
      "Application Status Updated",
      `Your application for ${updatedApplication.job.title} was marked as ${status}.`,
      { type: "status_updated", applicationId: updatedApplication.id }
    );
  }

  return updatedApplication;
};
