import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    ParseIntPipe,
    Patch,
    Post,
    Query,
    UploadedFile,
    UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';

import { RfisService } from './rfis.service';
import { CreateRfiDto } from './dto/create-rfi.dto';
import { UpdateRfiDto } from './dto/update-rfi.dto';
import { CurrentUser } from '../common/current-user.decorator';
import { AuthenticatedUser } from '../common/auth-user.interface';


@Controller('rfis')
export class RfisController {
    constructor(private readonly rfisService: RfisService) { }

    @Post()
    async create(
        @Body() createRfiDto: CreateRfiDto,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.rfisService.create(createRfiDto, user);
    }

    @Get('project/:projectId')
    async findByProject(
        @Param('projectId', ParseIntPipe) projectId: number,
        @CurrentUser() user: AuthenticatedUser,
        @Query('status') status?: string,
        @Query('assignedToId') assignedToId?: string,
        @Query('rfiNumber') rfiNumber?: string,
        @Query('dateFrom') dateFrom?: string,
        @Query('dateTo') dateTo?: string,
    ) {
        return this.rfisService.findByProject(projectId, user, {
            status,
            assignedToId: assignedToId ? Number(assignedToId) : undefined,
            rfiNumber,
            dateFrom,
            dateTo,
        });
    }

    @Get(':id')
    async findOne(
        @Param('id', ParseIntPipe) id: number,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.rfisService.findOne(id, user);
    }

    @Patch(':id')
    async update(
        @Param('id', ParseIntPipe) id: number,
        @Body() updateRfiDto: UpdateRfiDto,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.rfisService.update(id, updateRfiDto, user);
    }

    @Post(':id/attachments')
    @UseInterceptors(
        FileInterceptor('file', {
            storage: memoryStorage(),
            limits: {
                fileSize: 25 * 1024 * 1024,
            },
        }),
    )
    async uploadAttachment(
        @Param('id', ParseIntPipe) id: number,
        @UploadedFile() file: Express.Multer.File,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.rfisService.addAttachment(id, file, user);
    }

    @Delete('attachments/:attachmentId')
    async deleteAttachment(
        @Param('attachmentId', ParseIntPipe) attachmentId: number,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.rfisService.deleteAttachment(attachmentId, user);
    }

    @Delete(':id')
    async remove(
        @Param('id', ParseIntPipe) id: number,
        @CurrentUser() user: AuthenticatedUser,
    ) {
        return this.rfisService.remove(id, user);
    }
}
