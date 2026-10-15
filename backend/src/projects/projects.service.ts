import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { AuthenticatedUser } from '../common/auth-user.interface';
import {
  assertProjectAccess,
  getAccessibleProjectIds,
} from '../common/project-access.util';

@Injectable()
export class ProjectsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(user: AuthenticatedUser) {
    const accessibleProjectIds = await getAccessibleProjectIds(
      this.prisma,
      user,
    );

    return this.prisma.project.findMany({
      where:
        accessibleProjectIds === null
          ? undefined
          : { id: { in: accessibleProjectIds } },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  /**
   * The team assigned to a project — the only users an RFI (or any
   * other project-scoped feature) is allowed to be referred/assigned
   * to. Requires the requester to have access to the project too.
   */
  async findMembers(projectId: number, user: AuthenticatedUser) {
    await assertProjectAccess(this.prisma, user, projectId);

    const access = await this.prisma.userProject.findMany({
      where: { projectId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true,
            jobTitle: true,
            isActive: true,
          },
        },
      },
      orderBy: { user: { name: 'asc' } },
    });

    return access.map((entry) => entry.user);
  }

  async create(createProjectDto: CreateProjectDto) {
    return this.prisma.project.create({
      data: {
        code: createProjectDto.code,
        name: createProjectDto.name,
        location: createProjectDto.location,
        description: createProjectDto.description,
        status: createProjectDto.status ?? 'Active',
      },
    });
  }
}