import { Controller, Get, UseGuards } from '@nestjs/common';
import { CasesService } from '../cases/cases.service';
import { AdminGuard } from '../auth/jwt-auth.guard';

@Controller('admin')
@UseGuards(AdminGuard)
export class AdminController {
  constructor(private readonly casesService: CasesService) {}

  /** Unanonymized case overview for the overseeing-institution dashboard. */
  @Get('cases')
  cases() {
    return this.casesService.adminCaseOverview();
  }
}
