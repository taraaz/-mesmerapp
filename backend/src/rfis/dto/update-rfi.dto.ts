import {
  RfiInspectionReportDto,
  RfiPurposeItemDto,
  RfiReviewerDto,
} from './create-rfi.dto';

export class UpdateRfiDto {
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

  assignedToId?: number | null;

  purposeItems?: RfiPurposeItemDto[];
  reviewers?: RfiReviewerDto[];
  inspectionReports?: RfiInspectionReportDto[];
}
