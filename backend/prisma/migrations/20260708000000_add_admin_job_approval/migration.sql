ALTER TYPE "JobStatus" RENAME TO "JobStatus_old";

CREATE TYPE "JobStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CLOSED');

ALTER TABLE "Job" ALTER COLUMN "status" DROP DEFAULT;

ALTER TABLE "Job"
ALTER COLUMN "status" TYPE "JobStatus"
USING (
  CASE
    WHEN "status"::text = 'OPEN' THEN 'APPROVED'
    ELSE "status"::text
  END
)::"JobStatus";

ALTER TABLE "Job" ALTER COLUMN "status" SET DEFAULT 'PENDING';

DROP TYPE "JobStatus_old";

ALTER TABLE "Job"
ADD COLUMN "rejectionReason" TEXT,
ADD COLUMN "approvedAt" TIMESTAMP(3),
ADD COLUMN "approvedById" TEXT,
ADD COLUMN "rejectedAt" TIMESTAMP(3),
ADD COLUMN "rejectedById" TEXT;

ALTER TABLE "Job"
ADD CONSTRAINT "Job_approvedById_fkey"
FOREIGN KEY ("approvedById") REFERENCES "User"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Job"
ADD CONSTRAINT "Job_rejectedById_fkey"
FOREIGN KEY ("rejectedById") REFERENCES "User"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "Job_approvedById_idx" ON "Job"("approvedById");
CREATE INDEX "Job_rejectedById_idx" ON "Job"("rejectedById");
