import {
  DailyReportEquipmentDto,
  DailyReportExecutedWorkDto,
  DailyReportMaterialDto,
  DailyReportNextDayWorkDto,
  DailyReportPersonnelDto,
} from './create-daily-report.dto';

export class UpdateDailyReportDto {
  reportDate?: string;

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

  personnel?: DailyReportPersonnelDto[];

  equipment?: DailyReportEquipmentDto[];

  executedWork?: DailyReportExecutedWorkDto[];

  materials?: DailyReportMaterialDto[];

  nextDayWork?: DailyReportNextDayWorkDto[];
}
