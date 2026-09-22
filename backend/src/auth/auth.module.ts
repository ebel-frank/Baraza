import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { AdminGuard, JwtAuthGuard } from './jwt-auth.guard';

if (!process.env.JWT_SECRET) {
  throw new Error(
    'JWT_SECRET is not set. Copy .env.example to .env and set a long random string before starting the backend.',
  );
}

const jwtModule = JwtModule.register({
  secret: process.env.JWT_SECRET,
  signOptions: { expiresIn: '90d' },
});

@Module({
  imports: [jwtModule],
  controllers: [AuthController],
  providers: [AuthService, JwtAuthGuard, AdminGuard],
  // Re-export JwtModule too: @UseGuards(JwtAuthGuard) instantiates the guard fresh
  // inside whichever module uses it, so that module's own injector needs JwtService.
  exports: [JwtAuthGuard, AdminGuard, jwtModule],
})
export class AuthModule {}
