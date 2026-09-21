import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AuthModule } from '../auth/auth.module';
import { CasesModule } from '../cases/cases.module';

@Module({
  imports: [AuthModule, CasesModule],
  controllers: [AdminController],
})
export class AdminModule {}
