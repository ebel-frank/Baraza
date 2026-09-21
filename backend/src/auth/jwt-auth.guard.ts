import { CanActivate, ExecutionContext, ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

export interface AuthenticatedRequest extends Request {
  mediatorId: string;
  username: string;
  role: string;
}

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token.');
    }
    const token = authHeader.slice('Bearer '.length);
    try {
      const payload = this.jwtService.verify<{ sub: string; username: string; role?: string }>(token);
      req.mediatorId = payload.sub;
      req.username = payload.username;
      req.role = payload.role ?? 'mediator';
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token — please sign in again.');
    }
  }
}

/** Same token check as JwtAuthGuard, plus requires the "admin" role — for the
 * overseeing-institution case dashboard, which shows unanonymized case data. */
@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly jwtAuthGuard: JwtAuthGuard) {}

  canActivate(context: ExecutionContext): boolean {
    this.jwtAuthGuard.canActivate(context);
    const req = context.switchToHttp().getRequest<AuthenticatedRequest>();
    if (req.role !== 'admin') {
      throw new ForbiddenException('Admin access only.');
    }
    return true;
  }
}
