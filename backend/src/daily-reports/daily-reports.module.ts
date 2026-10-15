import { Module } from '@nestjs/common';

import { PrismaModule } from '../prisma/prisma.module';
import { DailyReportsController } from './daily-reports.controller';
import { DailyReportsService } from './daily-reports.service';

@Module({
    imports: [PrismaModule],
    controllers: [DailyReportsController],
    providers: [DailyReportsService],
})
export class DailyReportsModule { }