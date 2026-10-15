import { Controller, Get, NotFoundException, Param, Res } from '@nestjs/common';
import { Response } from 'express';

import { Public } from '../common/public.decorator';
import { StorageService } from './storage.service';

/**
 * Serves `/uploads/<path>` from Supabase Storage by redirecting to a
 * short-lived signed URL. Public like the old static `/uploads` folder,
 * because the app loads images with plain <img>/Image.network requests.
 * In local-disk mode main.ts serves `/uploads` statically instead and
 * those requests never reach this controller.
 */
@Controller('uploads')
export class StorageController {
    constructor(private readonly storage: StorageService) { }

    @Public()
    @Get('*path')
    async serve(
        @Param('path') path: string | string[],
        @Res() res: Response,
    ) {
        const relativePath = Array.isArray(path) ? path.join('/') : path;

        if (relativePath.split('/').includes('..')) {
            throw new NotFoundException();
        }

        const url = await this.storage.signedUrl(relativePath);

        if (!url) {
            throw new NotFoundException();
        }

        res.redirect(302, url);
    }
}
