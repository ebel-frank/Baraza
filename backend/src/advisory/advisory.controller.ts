import { Body, Controller, Post, Req, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { AdvisoryService } from './advisory.service';
import { AdvisoryQueryDto } from './dto/advisory-query.dto';
import { JwtAuthGuard, AuthenticatedRequest } from '../auth/jwt-auth.guard';

const MAX_AUDIO_BYTES = 20 * 1024 * 1024; // short voice notes only — this is a demo, not a media host
const MAX_AUDIO_FILES = 10;

@Controller('advisory')
export class AdvisoryController {
  constructor(private readonly advisoryService: AdvisoryService) {}

  @UseGuards(JwtAuthGuard)
  @Post('query')
  @UseInterceptors(FilesInterceptor('audio', MAX_AUDIO_FILES, { limits: { fileSize: MAX_AUDIO_BYTES } }))
  async query(
    @Req() req: AuthenticatedRequest,
    @Body() dto: AdvisoryQueryDto,
    @UploadedFiles() audio?: Express.Multer.File[],
  ) {
    const audioClips = (audio ?? []).map((file) => ({
      buffer: file.buffer,
      mimeType: file.mimetype || 'audio/wav',
    }));
    return this.advisoryService.query(dto.description, dto.caseId, req.mediatorId, audioClips);
  }
}
