import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { CasesModule } from './cases/cases.module';
import { AdvisoryModule } from './advisory/advisory.module';
import { ReferralModule } from './referral/referral.module';

@Module({
  imports: [PrismaModule, AuthModule, CasesModule, AdvisoryModule, ReferralModule],
})
export class AppModule {}
