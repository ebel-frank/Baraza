import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsDateString, IsOptional, IsString, ValidateNested } from 'class-validator';

export class CasePayloadDto {
  @IsString()
  id: string;

  @IsString()
  caseType: string;

  @IsArray()
  parties: { role: string }[];

  @IsString()
  description: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  voiceNoteRefs?: string[];

  @IsString()
  location: string;

  @IsDateString()
  createdAt: string;

  @IsBoolean()
  referralFlag: boolean;

  @IsOptional()
  @IsString()
  referralReason?: string;

  @IsOptional()
  advisoryResponse?: unknown;
}

export class SyncPushDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CasePayloadDto)
  cases: CasePayloadDto[];
}
