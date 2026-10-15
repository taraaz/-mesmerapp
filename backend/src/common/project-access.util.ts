import { ForbiddenException } from '@nestjs/common';
import { Role } from '../../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from './auth-user.interface';

/**
 * Throws ForbiddenException unless `user` is a Main Admin or has an
 * explicit UserProject assignment for `projectId`. This is the single
 * choke point that stops a user from reaching another project's data
 * by changing an ID in the URL, body, or query string.
 */
export async function assertProjectAccess(
  prisma: PrismaService,
  user: AuthenticatedUser,
  projectId: number,
): Promise<void> {
  if (user.role === Role.MAIN_ADMIN) {
    return;
  }

  const access = await prisma.userProject.findUnique({
    where: {
      userId_projectId: {
        userId: user.id,
        projectId,
      },
    },
  });

  if (!access) {
    throw new ForbiddenException(
      'You do not have access to this project',
    );
  }
}

/**
 * Throws ForbiddenException unless `targetUserId` is a Main Admin or has
 * an explicit UserProject assignment for `projectId`. Used whenever one
 * user (e.g. an RFI creator) tries to hand a record to another user, so
 * that assignment can never reach someone outside the project.
 */
export async function assertUserHasProjectAccess(
  prisma: PrismaService,
  targetUserId: number,
  projectId: number,
): Promise<void> {
  const targetUser = await prisma.user.findUnique({
    where: { id: targetUserId },
    select: { role: true },
  });

  if (!targetUser) {
    throw new ForbiddenException('Assigned user was not found');
  }

  if (targetUser.role === Role.MAIN_ADMIN) {
    return;
  }

  const access = await prisma.userProject.findUnique({
    where: {
      userId_projectId: {
        userId: targetUserId,
        projectId,
      },
    },
  });

  if (!access) {
    throw new ForbiddenException(
      'The assigned user does not have access to this project',
    );
  }
}

export async function getAccessibleProjectIds(
  prisma: PrismaService,
  user: AuthenticatedUser,
): Promise<number[] | null> {
  if (user.role === Role.MAIN_ADMIN) {
    return null;
  }

  const rows = await prisma.userProject.findMany({
    where: { userId: user.id },
    select: { projectId: true },
  });

  return rows.map((row) => row.projectId);
}
