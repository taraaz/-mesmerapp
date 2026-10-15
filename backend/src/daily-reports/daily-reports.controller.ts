import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    ParseIntPipe,
    Patch,
    Post,
    UploadedFile,
    UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { mkdirSync } from 'fs';

import { DailyReportsService } from './daily-reports.service';
import { CreateDailyReportDto } from './dto/create-daily-report.dto';
import { UpdateDailyReportDto } from './dto/update-daily-report.dto';
import { CurrentUser } from '../common/current-user.decorator';
import { AuthenticatedUser } from '../common/auth-user.interface';
import { Roles } from '../common/roles.decorator';
import { Role } from '../../generated/prisma/client';

const UPLOADS_ROOT = join(process.cwd(), 'uploads');

@Controller('daily-reports')
export class DailyReportsController {
    constructor(
        private readonly dailyReportsService: DailyReportsService,
    ) { }

    @Post()
    async create(
        @Body() createDailyReportDto: CreateDailyReportDto,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.dailyReportsService.create(createDailyReportDto, user);
    }

    @Get()
    @Roles(Role.MAIN_ADMIN)
    async findAll() {
        return this.dailyReportsService.findAll();
    }

    @Get('project/:projectId')
    async findByProject(
        @Param('projectId', ParseIntPipe) projectId: number,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.dailyReportsService.findByProject(projectId, user);
    }

    @Get(':id')
    async findOne(
        @Param('id', ParseIntPipe) id: number,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.dailyReportsService.findOne(id, user);
    }

    @Patch(':id')
    async update(
        @Param('id', ParseIntPipe) id: number,
        @Body() updateDailyReportDto: UpdateDailyReportDto,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.dailyReportsService.update(id, updateDailyReportDto, user);
    }

    @Post(':id/attachments')
    @UseInterceptors(
        FileInterceptor('file', {
            storage: diskStorage({
                destination: (req, _file, cb) => {
                    const reportId = String(req.params.id);

                    const dir = join(
                        UPLOADS_ROOT,
                        'daily-reports',
                        reportId,
                    );

                    mkdirSync(dir, { recursive: true });

                    cb(null, dir);
                },
                filename: (_req, file, cb) => {
                    const unique = `${Date.now()}-${Math.round(
                        Math.random() * 1e9,
                    )}`;

                    cb(null, `${unique}${extname(file.originalname)}`);
                },
            }),
            limits: {
                fileSize: 25 * 1024 * 1024,
            },
        }),
    )
    async uploadAttachment(
        @Param('id', ParseIntPipe) id: number,
        @UploadedFile() file: Express.Multer.File,
        @CurrentUser() user: AuthenticatedUser,
        @Body('isPhoto') isPhoto?: string,
    ) {
        return this.dailyReportsService.addAttachment(
            id,
            file,
            isPhoto === 'true',
            user,
        );
    }

    @Delete('attachments/:attachmentId')
    async deleteAttachment(
        @Param('attachmentId', ParseIntPipe) attachmentId: number,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.dailyReportsService.deleteAttachment(attachmentId, user);
    }

    @Delete(':id')
    async remove(
        @Param('id', ParseIntPipe) id: number,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.dailyReportsService.remove(id, user);
    }
}
