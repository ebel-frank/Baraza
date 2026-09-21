import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { CasesModule } from './cases/cases.module';
import { AdvisoryModule } from './advisory/advisory.module';
import { ReferralModule } from './referral/referral.module';
import { HealthModule } from './health/health.module';
import { AdminModule } from './admin/admin.module';

@Module({
  imports: [PrismaModule, AuthModule, CasesModule, AdvisoryModule, ReferralModule, HealthModule, AdminModule],
})
export class AppModule {}
