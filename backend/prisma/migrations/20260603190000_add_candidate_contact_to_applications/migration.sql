ALTER TABLE "User" ADD COLUMN "phone" TEXT;

ALTER TABLE "Application"
ADD COLUMN "applicantEmail" TEXT,
ADD COLUMN "applicantPhone" TEXT;
