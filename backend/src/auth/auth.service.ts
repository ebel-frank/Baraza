import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { Mediator } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

export interface PublicMediator {
  id: string;
  username: string;
  fullName: string;
  country: string;
  region: string;
  locality: string;
  role: string;
}

export interface AuthResult {
  token: string;
  mediator: PublicMediator;
}

const BCRYPT_ROUNDS = 10;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResult> {
    const existing = await this.prisma.mediator.findUnique({ where: { username: dto.username } });
    if (existing) {
      throw new ConflictException('That username is already taken.');
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const mediator = await this.prisma.mediator.create({
      data: {
        id: uuidv4(),
        username: dto.username,
        passwordHash,
        fullName: dto.fullName,
        country: dto.country,
        region: dto.region,
        locality: dto.locality,
      },
    });

    return { token: this.signToken(mediator), mediator: this.toPublic(mediator) };
  }

  async login(dto: LoginDto): Promise<AuthResult> {
    const mediator = await this.prisma.mediator.findUnique({ where: { username: dto.username } });
    if (!mediator) {
      throw new UnauthorizedException('Incorrect username or password.');
    }
    const valid = await bcrypt.compare(dto.password, mediator.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Incorrect username or password.');
    }
    return { token: this.signToken(mediator), mediator: this.toPublic(mediator) };
  }

  private signToken(mediator: Mediator): string {
    return this.jwtService.sign({
      sub: mediator.id,
      username: mediator.username,
      role: mediator.role ?? 'mediator',
    });
  }

  private toPublic(mediator: Mediator): PublicMediator {
    return {
      id: mediator.id,
      username: mediator.username,
      fullName: mediator.fullName,
      country: mediator.country,
      region: mediator.region,
      locality: mediator.locality,
      role: mediator.role ?? 'mediator',
    };
  }
}
