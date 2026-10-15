import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { CreateDailyReportDto } from './dto/create-daily-report.dto';
import { UpdateDailyReportDto } from './dto/update-daily-report.dto';
import { AuthenticatedUser } from '../common/auth-user.interface';
import { assertProjectAccess } from '../common/project-access.util';


@Injectable()
export class DailyReportsService {
    constructor(
        private readonly prisma: PrismaService,
        private readonly storage: StorageService,
    ) { }

    async create(dto: CreateDailyReportDto, user: AuthenticatedUser) {
        // Make sure the project exists.
        const project = await this.prisma.project.findUnique({
            where: {
                id: dto.projectId,
            },
        });

        if (!project) {
            throw new NotFoundException(
                `Project with ID ${dto.projectId} was not found`,
            );
        }

        await assertProjectAccess(this.prisma, user, dto.projectId);

        return this.prisma.dailyReport.create({
            data: {
                projectId: dto.projectId,

                reportDate: new Date(dto.reportDate),

                weather: dto.weather,
                windSpeed: dto.windSpeed,
                temperature: dto.temperature,
                moisture: dto.moisture,

                generalIssues: dto.generalIssues,

                status: dto.status ?? 'Draft',

                preparedBy: dto.preparedBy,
                preparedByRole: dto.preparedByRole,

                confirmedBy: dto.confirmedBy,
                confirmedByRole: dto.confirmedByRole,

                approvedBy: dto.approvedBy,
                approvedByRole: dto.approvedByRole,

                personnel: {
                    create: dto.personnel ?? [],
                },

                equipment: {
                    create: dto.equipment ?? [],
                },

                executedWork: {
                    create: dto.executedWork ?? [],
                },

                materials: {
                    create: dto.materials ?? [],
                },

                nextDayWork: {
                    create: dto.nextDayWork ?? [],
                },
            },

            include: {
                project: true,
                personnel: true,
                equipment: true,
                executedWork: true,
                materials: true,
                nextDayWork: true,
                attachments: true,
            },
        });
    }

    async findAll() {
        return this.prisma.dailyReport.findMany({
            include: {
                project: true,
                personnel: true,
                equipment: true,
                executedWork: true,
                materials: true,
                nextDayWork: true,
                attachments: true,
            },
            orderBy: {
                reportDate: 'desc',
            },
        });
    }

    async findByProject(projectId: number, user: AuthenticatedUser) {
        await assertProjectAccess(this.prisma, user, projectId);

        return this.prisma.dailyReport.findMany({
            where: {
                projectId,
            },
            include: {
                personnel: true,
                equipment: true,
                executedWork: true,
                materials: true,
                nextDayWork: true,
                attachments: true,
            },
            orderBy: {
                reportDate: 'desc',
            },
        });
    }

    async update(
        id: number,
        dto: UpdateDailyReportDto,
        user: AuthenticatedUser,
    ) {
        const existing = await this.prisma.dailyReport.findUnique({
            where: { id },
        });

        if (!existing) {
            throw new NotFoundException(
                `Daily Report with ID ${id} was not found`,
            );
        }

        await assertProjectAccess(this.prisma, user, existing.projectId);

        return this.prisma.dailyReport.update({
            where: { id },
            data: {
                ...(dto.reportDate !== undefined && {
                    reportDate: new Date(dto.reportDate),
                }),

                weather: dto.weather,
                windSpeed: dto.windSpeed,
                temperature: dto.temperature,
                moisture: dto.moisture,

                generalIssues: dto.generalIssues,

                ...(dto.status !== undefined && { status: dto.status }),

                preparedBy: dto.preparedBy,
                preparedByRole: dto.preparedByRole,

                confirmedBy: dto.confirmedBy,
                confirmedByRole: dto.confirmedByRole,

                approvedBy: dto.approvedBy,
                approvedByRole: dto.approvedByRole,

                ...(dto.personnel !== undefined && {
                    personnel: {
                        deleteMany: {},
                        create: dto.personnel,
                    },
                }),

                ...(dto.equipment !== undefined && {
                    equipment: {
                        deleteMany: {},
                        create: dto.equipment,
                    },
                }),

                ...(dto.executedWork !== undefined && {
                    executedWork: {
                        deleteMany: {},
                        create: dto.executedWork,
                    },
                }),

                ...(dto.materials !== undefined && {
                    materials: {
                        deleteMany: {},
                        create: dto.materials,
                    },
                }),

                ...(dto.nextDayWork !== undefined && {
                    nextDayWork: {
                        deleteMany: {},
                        create: dto.nextDayWork,
                    },
                }),
            },

            include: {
                project: true,
                personnel: true,
                equipment: true,
                executedWork: true,
                materials: true,
                nextDayWork: true,
                attachments: true,
            },
        });
    }

    async findOne(id: number, user: AuthenticatedUser) {
        const report =
            await this.prisma.dailyReport.findUnique({
                where: {
                    id,
                },
                include: {
                    project: true,
                    personnel: true,
                    equipment: true,
                    executedWork: true,
                    materials: true,
                    nextDayWork: true,
                    attachments: true,
                },
            });

        if (!report) {
            throw new NotFoundException(
                `Daily Report with ID ${id} was not found`,
            );
        }

        await assertProjectAccess(this.prisma, user, report.projectId);

        return report;
    }

    async addAttachment(
        dailyReportId: number,
        file: Express.Multer.File,
        isPhoto: boolean,
        user: AuthenticatedUser,
    ) {
        if (!file) {
            throw new NotFoundException('No file was uploaded');
        }

        const report = await this.prisma.dailyReport.findUnique({
            where: { id: dailyReportId },
        });

        if (!report) {
            throw new NotFoundException(
                `Daily Report with ID ${dailyReportId} was not found`,
            );
        }

        await assertProjectAccess(this.prisma, user, report.projectId);

        const storedName = this.storage.makeStoredName(file.originalname);
        const relativePath = `daily-reports/${dailyReportId}/${storedName}`;

        await this.storage.save(relativePath, file.buffer, file.mimetype);

        return this.prisma.dailyReportAttachment.create({
            data: {
                dailyReportId,
                originalName: file.originalname,
                storedName,
                mimeType: file.mimetype,
                fileSize: file.size,
                filePath: relativePath,
                isPhoto,
            },
        });
    }

    async deleteAttachment(attachmentId: number, user: AuthenticatedUser) {
        const attachment =
            await this.prisma.dailyReportAttachment.findUnique({
                where: { id: attachmentId },
                include: {
                    dailyReport: { select: { projectId: true } },
                },
            });

        if (!attachment) {
            throw new NotFoundException(
                `Attachment with ID ${attachmentId} was not found`,
            );
        }

        await assertProjectAccess(
            this.prisma,
            user,
            attachment.dailyReport.projectId,
        );

        await this.storage.remove(attachment.filePath);

        await this.prisma.dailyReportAttachment.delete({
            where: { id: attachmentId },
        });

        return { success: true };
    }

    async remove(id: number, user: AuthenticatedUser) {
        const report = await this.prisma.dailyReport.findUnique({
            where: { id },
            include: { attachments: true },
        });

        if (!report) {
            throw new NotFoundException(
                `Daily Report with ID ${id} was not found`,
            );
        }

        await assertProjectAccess(this.prisma, user, report.projectId);

        for (const attachment of report.attachments) {
            await this.storage.remove(attachment.filePath);
        }

        await this.prisma.dailyReport.delete({ where: { id } });

        return { success: true };
    }
}
