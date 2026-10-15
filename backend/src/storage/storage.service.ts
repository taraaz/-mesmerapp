import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { mkdir, unlink, writeFile } from 'fs/promises';
import { dirname, extname, join } from 'path';

export const UPLOADS_ROOT = join(process.cwd(), 'uploads');

const BUCKET = process.env.SUPABASE_STORAGE_BUCKET ?? 'uploads';
const SIGNED_URL_TTL_SECONDS = 60 * 60;

/**
 * Stores attachment files. Uses a private Supabase Storage bucket when
 * SUPABASE_PROJECT_URL and SUPABASE_SERVICE_ROLE_KEY are set (hosted
 * deployments, whose disks are wiped on redeploy); otherwise falls back
 * to the local `uploads/` folder for development.
 *
 * Paths are always relative, e.g. `daily-reports/5/<storedName>`, and are
 * what the attachment tables keep in `filePath`.
 */
@Injectable()
export class StorageService implements OnModuleInit {
    private readonly logger = new Logger(StorageService.name);
    private readonly supabase: SupabaseClient | null;

    constructor() {
        const url = process.env.SUPABASE_PROJECT_URL;
        const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

        this.supabase =
            url && key
                ? createClient(url, key, { auth: { persistSession: false } })
                : null;
    }

    get usesSupabase(): boolean {
        return this.supabase !== null;
    }

    async onModuleInit(): Promise<void> {
        if (!this.supabase) {
            this.logger.log(`Storing uploads on local disk at ${UPLOADS_ROOT}`);
            return;
        }

        const { data } = await this.supabase.storage.getBucket(BUCKET);

        if (!data) {
            const { error } = await this.supabase.storage.createBucket(BUCKET, {
                public: false,
            });

            if (error) {
                throw new Error(
                    `Could not create storage bucket "${BUCKET}": ${error.message}`,
                );
            }
        }

        this.logger.log(`Storing uploads in Supabase bucket "${BUCKET}"`);
    }

    /** Builds a unique stored file name that keeps the original extension. */
    makeStoredName(originalName: string): string {
        const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;

        return `${unique}${extname(originalName)}`;
    }

    async save(
        relativePath: string,
        content: Buffer,
        mimeType: string,
    ): Promise<void> {
        if (this.supabase) {
            const { error } = await this.supabase.storage
                .from(BUCKET)
                .upload(relativePath, content, { contentType: mimeType });

            if (error) {
                throw new Error(`Upload failed: ${error.message}`);
            }

            return;
        }

        const fullPath = join(UPLOADS_ROOT, relativePath);
        await mkdir(dirname(fullPath), { recursive: true });
        await writeFile(fullPath, content);
    }

    /** Deletes a stored file; a file that is already missing is ignored. */
    async remove(relativePath: string): Promise<void> {
        try {
            if (this.supabase) {
                await this.supabase.storage.from(BUCKET).remove([relativePath]);
            } else {
                await unlink(join(UPLOADS_ROOT, relativePath));
            }
        } catch {
            // The DB row is the source of truth; continue regardless.
        }
    }

    /** Short-lived link to a file in Supabase Storage, or null if missing. */
    async signedUrl(relativePath: string): Promise<string | null> {
        if (!this.supabase) {
            return null;
        }

        const { data } = await this.supabase.storage
            .from(BUCKET)
            .createSignedUrl(relativePath, SIGNED_URL_TTL_SECONDS);

        return data?.signedUrl ?? null;
    }
}
