export class DailyReportPersonnelDto {
  category!: string;
  position!: string;
  count!: number;
}

export class DailyReportEquipmentDto {
  equipment!: string;
  active!: number;
  total!: number;
}

export class DailyReportExecutedWorkDto {
  location!: string;
  description!: string;
  unit?: string;
  totalPhysicalVolume?: string;
  sinceBeginning?: string;
  quantity?: string;
  completedPercent?: string;
}

export class DailyReportMaterialDto {
  material!: string;
  unit?: string;
  number?: string;
}

export class DailyReportNextDayWorkDto {
  location!: string;
  description!: string;
}

export class CreateDailyReportDto {
  projectId!: number;

  reportDate!: string;

  weather?: string;
  windSpeed?: number;
  temperature?: number;
  moisture?: number;

  generalIssues?: string;

  status?: string;

  preparedBy?: string;
  preparedByRole?: string;

  confirmedBy?: string;
  confirmedByRole?: string;

  approvedBy?: string;
  approvedByRole?: string;

  personnel!: DailyReportPersonnelDto[];

  equipment!: DailyReportEquipmentDto[];

  executedWork!: DailyReportExecutedWorkDto[];

  materials!: DailyReportMaterialDto[];

  nextDayWork!: DailyReportNextDayWorkDto[];
}