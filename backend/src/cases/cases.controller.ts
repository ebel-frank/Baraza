import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { CasesService } from './cases.service';
import { SyncPushDto } from './dto/sync-push.dto';
import { JwtAuthGuard, AuthenticatedRequest } from '../auth/jwt-auth.guard';

@Controller()
export class CasesController {
  constructor(private readonly casesService: CasesService) {}

  @UseGuards(JwtAuthGuard)
  @Post('sync/push')
  push(@Req() req: AuthenticatedRequest, @Body() dto: SyncPushDto) {
    return this.casesService.push(req.mediatorId, dto);
  }

  /** Lets a signed-in mediator recover their synced cases on a new/reinstalled device. */
  @UseGuards(JwtAuthGuard)
  @Get('sync/pull')
  pull(@Req() req: AuthenticatedRequest) {
    return this.casesService.pull(req.mediatorId);
  }

  /** Stretch-goal: anonymized aggregate counts, e.g. for a simple read-only dashboard page. */
  @Get('stats/aggregate')
  aggregate() {
    return this.casesService.aggregateByTypeAndRegion();
  }
}
