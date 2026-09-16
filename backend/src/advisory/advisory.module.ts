import { Module } from '@nestjs/common';
import { AdvisoryService } from './advisory.service';
import { AdvisoryController } from './advisory.controller';
import { ReferralModule } from '../referral/referral.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [ReferralModule, AuthModule],
  controllers: [AdvisoryController],
  providers: [AdvisoryService],
})
export class AdvisoryModule {}
