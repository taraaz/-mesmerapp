import { Role } from '../../generated/prisma/client';

export interface AuthenticatedUser {
  id: number;
  name: string;
  email: string;
  role: Role;
  isActive: boolean;
}
