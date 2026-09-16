import { Controller, Get } from '@nestjs/common';
import { ReferralService } from './referral.service';

@Controller('referral')
export class ReferralController {
  constructor(private readonly referralService: ReferralService) {}

  /** Lets the mobile app pull the current category list instead of relying only on its bundled copy. */
  @Get('categories')
  getCategories() {
    return { categories: this.referralService.getCategories() };
  }
}
