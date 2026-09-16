import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SyncPushDto } from './dto/sync-push.dto';

@Injectable()
export class CasesService {
  constructor(private readonly prisma: PrismaService) {}

  async push(mediatorId: string, dto: SyncPushDto) {
    const syncedAt = new Date();
    const syncedIds: string[] = [];

    for (const c of dto.cases) {
      // Only ever create under, or update a case already owned by, the authenticated
      // mediator — never let one account's push overwrite another's case by id clash.
      const existing = await this.prisma.case.findUnique({ where: { id: c.id } });
      if (existing && existing.mediatorId !== mediatorId) {
        continue;
      }

      await this.prisma.case.upsert({
        where: { id: c.id },
        create: {
          id: c.id,
          mediatorId,
          caseType: c.caseType,
          parties: c.parties as any,
          description: c.description,
          voiceNoteRefs: c.voiceNoteRefs ?? [],
          location: c.location,
          createdAt: new Date(c.createdAt),
          syncedAt,
          referralFlag: c.referralFlag,
          referralReason: c.referralReason,
          advisoryResponse: (c.advisoryResponse as any) ?? undefined,
        },
        update: {
          caseType: c.caseType,
          parties: c.parties as any,
          description: c.description,
          voiceNoteRefs: c.voiceNoteRefs ?? [],
          location: c.location,
          referralFlag: c.referralFlag,
          referralReason: c.referralReason,
          syncedAt,
        },
      });
      syncedIds.push(c.id);
    }

    return { syncedAt: syncedAt.toISOString(), syncedIds };
  }

  /** Lets a mediator recover their synced cases after signing in on a (possibly new) device. */
  async pull(mediatorId: string) {
    const cases = await this.prisma.case.findMany({
      where: { mediatorId },
      orderBy: { createdAt: 'desc' },
    });
    return {
      cases: cases.map((c) => ({
        id: c.id,
        caseType: c.caseType,
        parties: c.parties,
        description: c.description,
        voiceNoteRefs: c.voiceNoteRefs,
        location: c.location,
        createdAt: c.createdAt.toISOString(),
        syncedAt: c.syncedAt ? c.syncedAt.toISOString() : null,
        referralFlag: c.referralFlag,
        referralReason: c.referralReason,
        advisoryResponse: c.advisoryResponse,
      })),
    };
  }

  /**
   * Anonymized counts for the stretch-goal read-only dashboard. Grouped in
   * application code rather than a DB-side join — Mongo has no cross-collection
   * joins via Prisma, and the case/mediator counts here are small enough that
   * this is simpler than an aggregation pipeline.
   */
  async aggregateByTypeAndRegion() {
    const [cases, mediators] = await Promise.all([
      this.prisma.case.findMany({ select: { mediatorId: true, caseType: true } }),
      this.prisma.mediator.findMany({ select: { id: true, region: true } }),
    ]);
    const regionByMediatorId = new Map(mediators.map((m) => [m.id, m.region]));

    const counts = new Map<string, { caseType: string; region: string; count: number }>();
    for (const c of cases) {
      const region = regionByMediatorId.get(c.mediatorId) ?? 'Unknown';
      const key = `${c.caseType}::${region}`;
      const existing = counts.get(key);
      if (existing) {
        existing.count += 1;
      } else {
        counts.set(key, { caseType: c.caseType, region, count: 1 });
      }
    }

    return [...counts.values()].sort(
      (a, b) => a.region.localeCompare(b.region) || a.caseType.localeCompare(b.caseType),
    );
  }
}
