import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { Prisma, Role, User } from '../../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../common/auth-user.interface';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

type UserWithAccess = User & {
  projectAccess: { projectId: number }[];
};

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(requester: AuthenticatedUser) {
    if (requester.role === Role.MAIN_ADMIN) {
      const users = await this.prisma.user.findMany({
        include: { projectAccess: { select: { projectId: true } } },
        orderBy: { createdAt: 'desc' },
      });

      return users.map((user) => this.toSummary(user));
    }

    // Project Managers only manage the Technical Experts on their own projects.
    const myProjectIds = await this.getOwnProjectIds(requester.id);

    const users = await this.prisma.user.findMany({
      where: {
        role: Role.TECHNICAL_EXPERT,
        projectAccess: {
          some: { projectId: { in: myProjectIds } },
        },
      },
      include: { projectAccess: { select: { projectId: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return users.map((user) => this.toSummary(user));
  }

  async findOne(id: number, requester: AuthenticatedUser) {
    const user = await this.getVisibleUserOrThrow(id, requester);
    return this.toSummary(user);
  }

  async create(dto: CreateUserDto, requester: AuthenticatedUser) {
    await this.assertCanManage(dto.role, dto.projectIds, requester);

    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existing) {
      throw new ConflictException(
        'A user with this email already exists',
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        name: dto.name,
        email: dto.email,
        passwordHash,
        role: dto.role,
        jobTitle: dto.jobTitle,
        description: dto.description,
        isActive: dto.isActive ?? true,
        projectAccess: {
          create: (dto.projectIds ?? []).map((projectId) => ({
            projectId,
          })),
        },
      },
      include: { projectAccess: { select: { projectId: true } } },
    });

    return this.toSummary(user);
  }

  async update(
    id: number,
    dto: UpdateUserDto,
    requester: AuthenticatedUser,
  ) {
    const existingUser = await this.getVisibleUserOrThrow(
      id,
      requester,
    );

    const nextRole = dto.role ?? existingUser.role;

    await this.assertCanManage(nextRole, dto.projectIds, requester);

    if (dto.email && dto.email !== existingUser.email) {
      const clash = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });

      if (clash) {
        throw new ConflictException(
          'A user with this email already exists',
        );
      }
    }

    const data: Prisma.UserUpdateInput = {
      name: dto.name,
      email: dto.email,
      role: dto.role,
      jobTitle: dto.jobTitle,
      description: dto.description,
      isActive: dto.isActive,
    };

    if (dto.password) {
      data.passwordHash = await bcrypt.hash(dto.password, 10);
    }

    if (dto.projectIds !== undefined) {
      data.projectAccess = {
        deleteMany: {},
        create: dto.projectIds.map((projectId) => ({
          projectId,
        })),
      };
    }

    const user = await this.prisma.user.update({
      where: { id },
      data,
      include: { projectAccess: { select: { projectId: true } } },
    });

    return this.toSummary(user);
  }

  private async getOwnProjectIds(userId: number): Promise<number[]> {
    const rows = await this.prisma.userProject.findMany({
      where: { userId },
      select: { projectId: true },
    });

    return rows.map((row) => row.projectId);
  }

  private async getVisibleUserOrThrow(
    id: number,
    requester: AuthenticatedUser,
  ): Promise<UserWithAccess> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { projectAccess: { select: { projectId: true } } },
    });

    if (!user) {
      throw new NotFoundException(
        `User with ID ${id} was not found`,
      );
    }

    if (requester.role === Role.MAIN_ADMIN) {
      return user;
    }

    if (requester.role === Role.PROJECT_MANAGER) {
      if (user.role !== Role.TECHNICAL_EXPERT) {
        throw new ForbiddenException();
      }

      const myProjectIds = await this.getOwnProjectIds(
        requester.id,
      );

      const sharesProject = user.projectAccess.some((access) =>
        myProjectIds.includes(access.projectId),
      );

      if (!sharesProject) {
        throw new ForbiddenException();
      }

      return user;
    }

    throw new ForbiddenException();
  }

  /**
   * Confirms `requester` is allowed to create/edit a user with the given
   * `role` and (if provided) grant exactly `projectIds` of project access.
   * Main Admin can do anything. A Project Manager may only manage
   * Technical Experts, and only ever grant access to projects the PM
   * themselves is assigned to.
   */
  private async assertCanManage(
    role: Role,
    projectIds: number[] | undefined,
    requester: AuthenticatedUser,
  ): Promise<void> {
    if (requester.role === Role.MAIN_ADMIN) {
      return;
    }

    if (requester.role !== Role.PROJECT_MANAGER) {
      throw new ForbiddenException(
        'You do not have permission to manage users',
      );
    }

    if (role !== Role.TECHNICAL_EXPERT) {
      throw new ForbiddenException(
        'Project Managers can only manage Technical Experts',
      );
    }

    if (projectIds === undefined) {
      return;
    }

    const myProjectIds = await this.getOwnProjectIds(requester.id);
    const outOfScope = projectIds.filter(
      (projectId) => !myProjectIds.includes(projectId),
    );

    if (outOfScope.length > 0) {
      throw new ForbiddenException(
        'You can only assign projects you manage',
      );
    }
  }

  private toSummary(user: UserWithAccess) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      jobTitle: user.jobTitle,
      description: user.description,
      isActive: user.isActive,
      createdAt: user.createdAt,
      projectIds: user.projectAccess.map(
        (access) => access.projectId,
      ),
    };
  }
}
