export class RfiPurposeItemDto {
  category!: string;
  item!: string;
}

export class RfiReviewerDto {
  discipline!: string;
  name?: string;
}

export class RfiInspectionReportDto {
  discipline?: string;
  remarks?: string;
  name?: string;
}

export class CreateRfiDto {
  projectId!: number;

  subject?: string;
  type?: string;
  revision?: string;
  enclosedCount?: number;

  requestDate?: string;
  inspectionTimeFrom?: string;
  inspectionTimeTo?: string;
  inspectionSequence?: string;

  location?: string;
  elevationLocation?: string;
  workType?: string;
  drawingNo?: string;

  othersSpecify?: string;
  particularDetails?: string;

  permittedWorkDescription?: string;
  approxQuantity?: string;

  submittedByName?: string;
  submittedDate?: string;
  receivedByName?: string;
  receivedDate?: string;

  engineerComment?: string;
  supervisorSignedName?: string;
  supervisorSignedDate?: string;

  status?: string;

  assignedToId?: number;

  purposeItems?: RfiPurposeItemDto[];
  reviewers?: RfiReviewerDto[];
  inspectionReports?: RfiInspectionReportDto[];
}
