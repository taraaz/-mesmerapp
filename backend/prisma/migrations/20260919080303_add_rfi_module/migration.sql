-- CreateTable
CREATE TABLE "Rfi" (
    "id" SERIAL NOT NULL,
    "projectId" INTEGER NOT NULL,
    "sequence" INTEGER NOT NULL,
    "rfiNumber" TEXT NOT NULL,
    "type" TEXT,
    "revision" TEXT DEFAULT '00',
    "enclosedCount" INTEGER DEFAULT 0,
    "requestDate" TIMESTAMP(3),
    "inspectionTimeFrom" TEXT,
    "inspectionTimeTo" TEXT,
    "inspectionSequence" TEXT,
    "location" TEXT,
    "elevationLocation" TEXT,
    "workType" TEXT,
    "drawingNo" TEXT,
    "othersSpecify" TEXT,
    "particularDetails" TEXT,
    "permittedWorkDescription" TEXT,
    "approxQuantity" TEXT,
    "submittedByName" TEXT,
    "submittedDate" TIMESTAMP(3),
    "receivedByName" TEXT,
    "receivedDate" TIMESTAMP(3),
    "engineerComment" TEXT,
    "supervisorSignedName" TEXT,
    "supervisorSignedDate" TIMESTAMP(3),
    "status" TEXT NOT NULL DEFAULT 'Draft',
    "createdById" INTEGER NOT NULL,
    "assignedToId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Rfi_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RfiPurposeItem" (
    "id" SERIAL NOT NULL,
    "rfiId" INTEGER NOT NULL,
    "category" TEXT NOT NULL,
    "item" TEXT NOT NULL,

    CONSTRAINT "RfiPurposeItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RfiReviewer" (
    "id" SERIAL NOT NULL,
    "rfiId" INTEGER NOT NULL,
    "discipline" TEXT NOT NULL,
    "name" TEXT,

    CONSTRAINT "RfiReviewer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RfiInspectionReport" (
    "id" SERIAL NOT NULL,
    "rfiId" INTEGER NOT NULL,
    "discipline" TEXT,
    "remarks" TEXT,
    "name" TEXT,

    CONSTRAINT "RfiInspectionReport_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RfiAttachment" (
    "id" SERIAL NOT NULL,
    "rfiId" INTEGER NOT NULL,
    "originalName" TEXT NOT NULL,
    "storedName" TEXT NOT NULL,
    "mimeType" TEXT,
    "fileSize" INTEGER,
    "filePath" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RfiAttachment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RfiStatusHistory" (
    "id" SERIAL NOT NULL,
    "rfiId" INTEGER NOT NULL,
    "status" TEXT NOT NULL,
    "note" TEXT,
    "changedById" INTEGER NOT NULL,
    "changedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RfiStatusHistory_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Rfi_projectId_rfiNumber_key" ON "Rfi"("projectId", "rfiNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Rfi_projectId_sequence_key" ON "Rfi"("projectId", "sequence");

-- AddForeignKey
ALTER TABLE "Rfi" ADD CONSTRAINT "Rfi_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Rfi" ADD CONSTRAINT "Rfi_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Rfi" ADD CONSTRAINT "Rfi_assignedToId_fkey" FOREIGN KEY ("assignedToId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfiPurposeItem" ADD CONSTRAINT "RfiPurposeItem_rfiId_fkey" FOREIGN KEY ("rfiId") REFERENCES "Rfi"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfiReviewer" ADD CONSTRAINT "RfiReviewer_rfiId_fkey" FOREIGN KEY ("rfiId") REFERENCES "Rfi"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfiInspectionReport" ADD CONSTRAINT "RfiInspectionReport_rfiId_fkey" FOREIGN KEY ("rfiId") REFERENCES "Rfi"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfiAttachment" ADD CONSTRAINT "RfiAttachment_rfiId_fkey" FOREIGN KEY ("rfiId") REFERENCES "Rfi"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfiStatusHistory" ADD CONSTRAINT "RfiStatusHistory_rfiId_fkey" FOREIGN KEY ("rfiId") REFERENCES "Rfi"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfiStatusHistory" ADD CONSTRAINT "RfiStatusHistory_changedById_fkey" FOREIGN KEY ("changedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
