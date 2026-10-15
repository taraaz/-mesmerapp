import { Module } from '@nestjs/common';

import { PrismaModule } from '../prisma/prisma.module';
import { RfisController } from './rfis.controller';
import { RfisService } from './rfis.service';

@Module({
    imports: [PrismaModule],
    controllers: [RfisController],
    providers: [RfisService],
})
export class RfisModule { }
