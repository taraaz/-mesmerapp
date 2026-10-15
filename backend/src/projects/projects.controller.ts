import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';

import { CreateProjectDto } from './dto/create-project.dto';
import { ProjectsService } from './projects.service';
import { CurrentUser } from '../common/current-user.decorator';
import { AuthenticatedUser } from '../common/auth-user.interface';
import { Roles } from '../common/roles.decorator';
import { Role } from '../../generated/prisma/client';

@Controller('projects')
export class ProjectsController {
  constructor(
    private readonly projectsService: ProjectsService,
  ) { }

  @Get()
  async findAll(@CurrentUser() user: AuthenticatedUser) {
    return this.projectsService.findAll(user);
  }

  @Get(':id/members')
  async findMembers(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.projectsService.findMembers(id, user);
  }

  @Post()
  @Roles(Role.MAIN_ADMIN)
  async create(
    @Body() createProjectDto: CreateProjectDto,
  ) {
    return this.projectsService.create(createProjectDto);
  }
}