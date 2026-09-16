import { IsOptional, IsString, MinLength } from 'class-validator';

export class AdvisoryQueryDto {
  @IsString()
  @MinLength(5)
  description: string;

  @IsOptional()
  @IsString()
  caseId?: string;
}
