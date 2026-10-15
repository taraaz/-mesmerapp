import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { CreateRfiDto } from './dto/create-rfi.dto';
import { UpdateRfiDto } from './dto/update-rfi.dto';
import { AuthenticatedUser } from '../common/auth-user.interface';
import {
    assertProjectAccess,
    assertUserHasProjectAccess,
} from '../common/project-access.util';


const RFI_INCLUDE = {
    project: {
        select: { id: true, code: true, name: true },
    },
    createdBy: {
        select: { id: true, name: true, email: true, role: true },
    },
    assignedTo: {
        select: { id: true, name: true, email: true, role: true },
    },
    purposeItems: true,
    reviewers: true,
    inspectionReports: true,
    attachments: true,
    statusHistory: {
        orderBy: { changedAt: 'asc' as const },
        include: {
            changedBy: { select: { id: true, name: true } },
        },
    },
};

export interface RfiListFilters {
    status?: string;
    assignedToId?: number;
    rfiNumber?: string;
    dateFrom?: string;
    dateTo?: string;
}

@Injectable()
export class RfisService {
    constructor(
        private readonly prisma: PrismaService,
        private readonly storage: StorageService,
    ) { }

    async create(dto: CreateRfiDto, user: AuthenticatedUser) {
        const project = await this.prisma.project.findUnique({
            where: { id: dto.projectId },
        });

        if (!project) {
            throw new NotFoundException(
                `Project with ID ${dto.projectId} was not found`,
            );
        }

        await assertProjectAccess(this.prisma, user, dto.projectId);

        if (dto.assignedToId) {
            await assertUserHasProjectAccess(
                this.prisma,
                dto.assignedToId,
                dto.projectId,
            );
        }

        return this.createWithUniqueNumber(dto, user);
    }

    private async createWithUniqueNumber(
        dto: CreateRfiDto,
        user: AuthenticatedUser,
        attempt = 0,
    ): Promise<unknown> {
        const last = await this.prisma.rfi.aggregate({
            where: { projectId: dto.projectId },
            _max: { sequence: true },
        });

        const nextSequence = (last._max.sequence ?? 0) + 1;
        // Matches the reference paper form's own numbering style (e.g.
        // "RFI-159") rather than embedding the project code — the number
        // only ever needs to be unique within the project it belongs to,
        // and it's always viewed inside that project's own RFI list.
        const rfiNumber = `RFI-${nextSequence}`;
        const status = dto.status ?? 'Draft';

        try {
            return await this.prisma.rfi.create({
                data: {
                    projectId: dto.projectId,
                    sequence: nextSequence,
                    rfiNumber,

                    subject: dto.subject,
                    type: dto.type,
                    revision: dto.revision ?? '00',
                    enclosedCount: dto.enclosedCount ?? 0,

                    requestDate: dto.requestDate
                        ? new Date(dto.requestDate)
                        : undefined,
                    inspectionTimeFrom: dto.inspectionTimeFrom,
                    inspectionTimeTo: dto.inspectionTimeTo,
                    inspectionSequence: dto.inspectionSequence,

                    location: dto.location,
                    elevationLocation: dto.elevationLocation,
                    workType: dto.workType,
                    drawingNo: dto.drawingNo,

                    othersSpecify: dto.othersSpecify,
                    particularDetails: dto.particularDetails,

                    permittedWorkDescription: dto.permittedWorkDescription,
                    approxQuantity: dto.approxQuantity,

                    submittedByName: dto.submittedByName,
                    submittedDate: dto.submittedDate
                        ? new Date(dto.submittedDate)
                        : undefined,
                    receivedByName: dto.receivedByName,
                    receivedDate: dto.receivedDate
                        ? new Date(dto.receivedDate)
                        : undefined,

                    engineerComment: dto.engineerComment,
                    supervisorSignedName: dto.supervisorSignedName,
                    supervisorSignedDate: dto.supervisorSignedDate
                        ? new Date(dto.supervisorSignedDate)
                        : undefined,

                    status,

                    createdById: user.id,
                    assignedToId: dto.assignedToId ?? undefined,

                    purposeItems: { create: dto.purposeItems ?? [] },
                    reviewers: { create: dto.reviewers ?? [] },
                    inspectionReports: {
                        create: dto.inspectionReports ?? [],
                    },
                    statusHistory: {
                        create: [{ status, changedById: user.id }],
                    },
                },
                include: RFI_INCLUDE,
            });
        } catch (error) {
            const isCollision =
                error instanceof Prisma.PrismaClientKnownRequestError &&
                error.code === 'P2002';

            if (isCollision && attempt < 5) {
                return this.createWithUniqueNumber(
                    dto,
                    user,
                    attempt + 1,
                );
            }

            throw error;
        }
    }

    async findByProject(
        projectId: number,
        user: AuthenticatedUser,
        filters: RfiListFilters,
    ) {
        await assertProjectAccess(this.prisma, user, projectId);

        const where: Prisma.RfiWhereInput = { projectId };

        if (filters.status) {
            where.status = filters.status;
        }

        if (filters.assignedToId) {
            where.assignedToId = filters.assignedToId;
        }

        if (filters.rfiNumber) {
            where.rfiNumber = {
                contains: filters.rfiNumber,
                mode: 'insensitive',
            };
        }

        if (filters.dateFrom || filters.dateTo) {
            where.requestDate = {
                ...(filters.dateFrom && { gte: new Date(filters.dateFrom) }),
                ...(filters.dateTo && { lte: new Date(filters.dateTo) }),
            };
        }

        return this.prisma.rfi.findMany({
            where,
            include: RFI_INCLUDE,
            orderBy: { sequence: 'desc' },
        });
    }

    async findOne(id: number, user: AuthenticatedUser) {
        const rfi = await this.prisma.rfi.findUnique({
            where: { id },
            include: RFI_INCLUDE,
        });

        if (!rfi) {
            throw new NotFoundException(`RFI with ID ${id} was not found`);
        }

        await assertProjectAccess(this.prisma, user, rfi.projectId);

        return rfi;
    }

    async update(id: number, dto: UpdateRfiDto, user: AuthenticatedUser) {
        const existing = await this.prisma.rfi.findUnique({
            where: { id },
        });

        if (!existing) {
            throw new NotFoundException(`RFI with ID ${id} was not found`);
        }

        await assertProjectAccess(this.prisma, user, existing.projectId);

        if (dto.assignedToId) {
            await assertUserHasProjectAccess(
                this.prisma,
                dto.assignedToId,
                existing.projectId,
            );
        }

        const statusChanged =
            dto.status !== undefined && dto.status !== existing.status;

        return this.prisma.rfi.update({
            where: { id },
            data: {
                subject: dto.subject,
                type: dto.type,
                revision: dto.revision,
                enclosedCount: dto.enclosedCount,

                ...(dto.requestDate !== undefined && {
                    requestDate: new Date(dto.requestDate),
                }),
                inspectionTimeFrom: dto.inspectionTimeFrom,
                inspectionTimeTo: dto.inspectionTimeTo,
                inspectionSequence: dto.inspectionSequence,

                location: dto.location,
                elevationLocation: dto.elevationLocation,
                workType: dto.workType,
                drawingNo: dto.drawingNo,

                othersSpecify: dto.othersSpecify,
                particularDetails: dto.particularDetails,

                permittedWorkDescription: dto.permittedWorkDescription,
                approxQuantity: dto.approxQuantity,

                submittedByName: dto.submittedByName,
                ...(dto.submittedDate !== undefined && {
                    submittedDate: new Date(dto.submittedDate),
                }),
                receivedByName: dto.receivedByName,
                ...(dto.receivedDate !== undefined && {
                    receivedDate: new Date(dto.receivedDate),
                }),

                engineerComment: dto.engineerComment,
                supervisorSignedName: dto.supervisorSignedName,
                ...(dto.supervisorSignedDate !== undefined && {
                    supervisorSignedDate: new Date(dto.supervisorSignedDate),
                }),

                ...(dto.status !== undefined && { status: dto.status }),

                ...(dto.assignedToId !== undefined && {
                    assignedToId: dto.assignedToId,
                }),

                ...(dto.purposeItems !== undefined && {
                    purposeItems: {
                        deleteMany: {},
                        create: dto.purposeItems,
                    },
                }),

                ...(dto.reviewers !== undefined && {
                    reviewers: {
                        deleteMany: {},
                        create: dto.reviewers,
                    },
                }),

                ...(dto.inspectionReports !== undefined && {
                    inspectionReports: {
                        deleteMany: {},
                        create: dto.inspectionReports,
                    },
                }),

                ...(statusChanged && {
                    statusHistory: {
                        create: [
                            {
                                status: dto.status!,
                                changedById: user.id,
                            },
                        ],
                    },
                }),
            },
            include: RFI_INCLUDE,
        });
    }

    async addAttachment(
        rfiId: number,
        file: Express.Multer.File,
        user: AuthenticatedUser,
    ) {
        if (!file) {
            throw new NotFoundException('No file was uploaded');
        }

        const rfi = await this.prisma.rfi.findUnique({
            where: { id: rfiId },
        });

        if (!rfi) {
            throw new NotFoundException(`RFI with ID ${rfiId} was not found`);
        }

        await assertProjectAccess(this.prisma, user, rfi.projectId);

        const storedName = this.storage.makeStoredName(file.originalname);
        const relativePath = `rfis/${rfiId}/${storedName}`;

        await this.storage.save(relativePath, file.buffer, file.mimetype);

        const attachment = await this.prisma.rfiAttachment.create({
            data: {
                rfiId,
                originalName: file.originalname,
                storedName,
                mimeType: file.mimetype,
                fileSize: file.size,
                filePath: relativePath,
            },
        });

        await this.prisma.rfi.update({
            where: { id: rfiId },
            data: { enclosedCount: { increment: 1 } },
        });

        return attachment;
    }

    async deleteAttachment(attachmentId: number, user: AuthenticatedUser) {
        const attachment = await this.prisma.rfiAttachment.findUnique({
            where: { id: attachmentId },
            include: { rfi: { select: { id: true, projectId: true } } },
        });

        if (!attachment) {
            throw new NotFoundException(
                `Attachment with ID ${attachmentId} was not found`,
            );
        }

        await assertProjectAccess(this.prisma, user, attachment.rfi.projectId);

        await this.storage.remove(attachment.filePath);

        await this.prisma.rfiAttachment.delete({ where: { id: attachmentId } });

        await this.prisma.rfi.update({
            where: { id: attachment.rfi.id },
            data: { enclosedCount: { decrement: 1 } },
        });

        return { success: true };
    }

    async remove(id: number, user: AuthenticatedUser) {
        const rfi = await this.prisma.rfi.findUnique({
            where: { id },
            include: { attachments: true },
        });

        if (!rfi) {
            throw new NotFoundException(`RFI with ID ${id} was not found`);
        }

        await assertProjectAccess(this.prisma, user, rfi.projectId);

        for (const attachment of rfi.attachments) {
            await this.storage.remove(attachment.filePath);
        }

        await this.prisma.rfi.delete({ where: { id } });

        return { success: true };
    }
}
