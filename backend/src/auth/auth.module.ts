import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtAuthGuard } from './jwt-auth.guard';

const jwtModule = JwtModule.register({
  // Demo-only fallback secret — set a real JWT_SECRET in .env before anything
  // beyond this hackathon demo.
  secret: process.env.JWT_SECRET ?? 'dev-only-insecure-secret-change-me',
  signOptions: { expiresIn: '90d' },
});

@Module({
  imports: [jwtModule],
  controllers: [AuthController],
  providers: [AuthService, JwtAuthGuard],
  // Re-export JwtModule too: @UseGuards(JwtAuthGuard) instantiates the guard fresh
  // inside whichever module uses it, so that module's own injector needs JwtService.
  exports: [JwtAuthGuard, jwtModule],
})
export class AuthModule {}
