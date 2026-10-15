import 'dotenv/config';

import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
import { mkdirSync } from 'fs';
import { AppModule } from './app.module';
import { UPLOADS_ROOT } from './storage/storage.service';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // NOTE: `whitelist: true` is intentionally omitted. None of this app's
  // DTOs use class-validator decorators, and with the installed
  // class-validator version, `whitelist` strips every property from any
  // undecorated DTO class (silently, with no validation error) rather
  // than leaving unknown-but-undecorated fields alone. That emptied every
  // POST/PATCH body before it reached a service. `transform: true` alone
  // still gives us DTO instantiation and primitive coercion for
  // query/param values.
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
    }),
  );

  app.enableCors({
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // Without Supabase Storage configured, attachments live in the local
  // uploads/ folder and are served from it directly. Otherwise
  // StorageController handles /uploads/* by redirecting to Supabase.
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    mkdirSync(UPLOADS_ROOT, { recursive: true });
    app.useStaticAssets(UPLOADS_ROOT, { prefix: '/uploads/' });
  }

  // Hosting platforms (e.g. Render) assign the port via PORT.
  await app.listen(process.env.PORT ?? 3000);
}

bootstrap();