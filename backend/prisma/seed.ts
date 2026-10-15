import 'dotenv/config';
import * as bcrypt from 'bcrypt';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, Role } from '../generated/prisma/client';

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});
const prisma = new PrismaClient({ adapter });

async function main() {
  const email = 'admin@mesmer.com';

  const existing = await prisma.user.findUnique({ where: { email } });

  if (existing) {
    console.log(`Main Admin already exists (${email}); skipping seed.`);
    return;
  }

  const password = process.env.SEED_ADMIN_PASSWORD;

  if (!password) {
    throw new Error('SEED_ADMIN_PASSWORD is not defined');
  }

  const passwordHash = await bcrypt.hash(password, 10);

  await prisma.user.create({
    data: {
      name: 'Main Admin',
      email,
      passwordHash,
      role: Role.MAIN_ADMIN,
      jobTitle: 'System Administrator',
      isActive: true,
    },
  });

  console.log(`Seeded bootstrap Main Admin: ${email}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
