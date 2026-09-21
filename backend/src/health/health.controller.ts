import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import { Response } from 'express';
import { PrismaService } from '../prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Unauthenticated on purpose — meant to be hit by anyone/anything (a
   * mediator's "is the backend up?" check, an uptime monitor, Render's own
   * health check) without needing a session. Confirms the DB is actually
   * reachable too, not just that the Nest process is alive.
   */
  @Get()
  async check(@Res() res: Response) {
    try {
      await this.prisma.$runCommandRaw({ ping: 1 });
      return res.status(HttpStatus.OK).json({
        status: 'ok',
        database: 'ok',
        timestamp: new Date().toISOString(),
      });
    } catch (err) {
      return res.status(HttpStatus.SERVICE_UNAVAILABLE).json({
        status: 'error',
        database: 'unreachable',
        message: err instanceof Error ? err.message : String(err),
        timestamp: new Date().toISOString(),
      });
    }
  }
}
