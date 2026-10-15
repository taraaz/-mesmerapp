-- CreateTable
CREATE TABLE "DailyReport" (
    "id" SERIAL NOT NULL,
    "projectId" INTEGER NOT NULL,
    "reportDate" TIMESTAMP(3) NOT NULL,
    "weather" TEXT,
    "windSpeed" DOUBLE PRECISION,
    "temperature" DOUBLE PRECISION,
    "moisture" DOUBLE PRECISION,
    "generalIssues" TEXT,
    "status" TEXT NOT NULL DEFAULT 'Draft',
    "preparedBy" TEXT,
    "preparedByRole" TEXT,
    "confirmedBy" TEXT,
    "confirmedByRole" TEXT,
    "approvedBy" TEXT,
    "approvedByRole" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DailyReport_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DailyReportPersonnel" (
    "id" SERIAL NOT NULL,
    "dailyReportId" INTEGER NOT NULL,
    "category" TEXT NOT NULL,
    "position" TEXT NOT NULL,
    "count" INTEGER NOT NULL,

    CONSTRAINT "DailyReportPersonnel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DailyReportEquipment" (
    "id" SERIAL NOT NULL,
    "dailyReportId" INTEGER NOT NULL,
    "equipment" TEXT NOT NULL,
    "active" INTEGER NOT NULL,
    "total" INTEGER NOT NULL,

    CONSTRAINT "DailyReportEquipment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DailyReportExecutedWork" (
    "id" SERIAL NOT NULL,
    "dailyReportId" INTEGER NOT NULL,
    "location" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "unit" TEXT,
    "totalPhysicalVolume" TEXT,
    "sinceBeginning" TEXT,
    "quantity" TEXT,
    "completedPercent" TEXT,

    CONSTRAINT "DailyReportExecutedWork_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DailyReportMaterial" (
    "id" SERIAL NOT NULL,
    "dailyReportId" INTEGER NOT NULL,
    "material" TEXT NOT NULL,
    "unit" TEXT,
    "number" TEXT,

    CONSTRAINT "DailyReportMaterial_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DailyReportNextDayWork" (
    "id" SERIAL NOT NULL,
    "dailyReportId" INTEGER NOT NULL,
    "location" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "DailyReportNextDayWork_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DailyReportAttachment" (
    "id" SERIAL NOT NULL,
    "dailyReportId" INTEGER NOT NULL,
    "originalName" TEXT NOT NULL,
    "storedName" TEXT NOT NULL,
    "mimeType" TEXT,
    "fileSize" INTEGER,
    "filePath" TEXT NOT NULL,
    "isPhoto" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DailyReportAttachment_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "DailyReport" ADD CONSTRAINT "DailyReport_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DailyReportPersonnel" ADD CONSTRAINT "DailyReportPersonnel_dailyReportId_fkey" FOREIGN KEY ("dailyReportId") REFERENCES "DailyReport"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DailyReportEquipment" ADD CONSTRAINT "DailyReportEquipment_dailyReportId_fkey" FOREIGN KEY ("dailyReportId") REFERENCES "DailyReport"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DailyReportExecutedWork" ADD CONSTRAINT "DailyReportExecutedWork_dailyReportId_fkey" FOREIGN KEY ("dailyReportId") REFERENCES "DailyReport"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DailyReportMaterial" ADD CONSTRAINT "DailyReportMaterial_dailyReportId_fkey" FOREIGN KEY ("dailyReportId") REFERENCES "DailyReport"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DailyReportNextDayWork" ADD CONSTRAINT "DailyReportNextDayWork_dailyReportId_fkey" FOREIGN KEY ("dailyReportId") REFERENCES "DailyReport"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DailyReportAttachment" ADD CONSTRAINT "DailyReportAttachment_dailyReportId_fkey" FOREIGN KEY ("dailyReportId") REFERENCES "DailyReport"("id") ON DELETE CASCADE ON UPDATE CASCADE;
