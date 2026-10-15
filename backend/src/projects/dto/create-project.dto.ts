export class CreateProjectDto {
    code!: string;
    name!: string;
    location!: string;
    description?: string;
    status?: string;
}