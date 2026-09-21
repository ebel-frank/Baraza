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
   * Anonymized, aggregate-only tension signal: never exposes a single case's
   * description/parties, only counts grouped by country/region/case type —
   * this is what lets mediators and coordinators across different
   * communities compare notes ("is this pattern local, or wider?") without
   * either side seeing the other's actual case data. `riskLevel` is a plain,
   * explicit threshold on recent referral-flagged (escalating) cases, not a
   * hidden model — same "editable config, not a black box" principle as the
   * referral categories themselves.
   *
   * Grouped in application code rather than a DB-side join — Mongo has no
   * cross-collection joins via Prisma, and the counts here are small enough
   * that this is simpler than an aggregation pipeline.
   */
  async aggregateByTypeAndRegion() {
    const [cases, mediators] = await Promise.all([
      this.prisma.case.findMany({
        select: { mediatorId: true, caseType: true, referralFlag: true, createdAt: true },
      }),
      this.prisma.mediator.findMany({ select: { id: true, region: true, country: true } }),
    ]);
    const mediatorInfo = new Map(mediators.map((m) => [m.id, { region: m.region, country: m.country }]));
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    interface Group {
      country: string;
      region: string;
      caseType: string;
      count: number;
      referralFlagCount: number;
      recentCount: number;
      recentReferralFlagCount: number;
    }
    const groups = new Map<string, Group>();
    for (const c of cases) {
      const info = mediatorInfo.get(c.mediatorId) ?? { region: 'Unknown', country: 'Unknown' };
      const key = `${info.country}::${info.region}::${c.caseType}`;
      let g = groups.get(key);
      if (!g) {
        g = {
          country: info.country,
          region: info.region,
          caseType: c.caseType,
          count: 0,
          referralFlagCount: 0,
          recentCount: 0,
          recentReferralFlagCount: 0,
        };
        groups.set(key, g);
      }
      g.count += 1;
      if (c.referralFlag) g.referralFlagCount += 1;
      if (c.createdAt >= thirtyDaysAgo) {
        g.recentCount += 1;
        if (c.referralFlag) g.recentReferralFlagCount += 1;
      }
    }

    return [...groups.values()]
      .map((g) => ({
        ...g,
        // Explicit thresholds on recent escalating cases — recorded here, not
        // hidden in a model, so a coordinator can see exactly why a region
        // is flagged. Tune freely as real data comes in.
        riskLevel: g.recentReferralFlagCount >= 2 ? 'high' : g.recentReferralFlagCount >= 1 ? 'medium' : 'low',
      }))
      .sort(
        (a, b) =>
          a.country.localeCompare(b.country) ||
          a.region.localeCompare(b.region) ||
          a.caseType.localeCompare(b.caseType),
      );
  }

  /**
   * Full, unanonymized case list for the overseeing-institution admin dashboard —
   * unlike aggregateByTypeAndRegion(), this deliberately exposes real case content
   * (description, parties, location) so a government/NGO admin can see exactly
   * what's arising and where. Gated by AdminGuard, never reachable by a mediator's
   * own token.
   */
  async adminCaseOverview() {
    const [cases, mediators] = await Promise.all([
      this.prisma.case.findMany({ orderBy: { createdAt: 'desc' } }),
      this.prisma.mediator.findMany({ select: { id: true, fullName: true, region: true, locality: true } }),
    ]);
    const mediatorInfo = new Map(mediators.map((m) => [m.id, m]));

    const casesWithContext = cases.map((c) => {
      const mediator = mediatorInfo.get(c.mediatorId);
      return {
        id: c.id,
        caseType: c.caseType,
        parties: c.parties,
        description: c.description,
        location: c.location,
        createdAt: c.createdAt.toISOString(),
        referralFlag: c.referralFlag,
        referralReason: c.referralReason,
        mediatorName: mediator?.fullName ?? 'Unknown mediator',
        region: mediator?.region ?? 'Unknown region',
        locality: mediator?.locality ?? 'Unknown locality',
      };
    });

    const regionTotals = new Map<string, { region: string; count: number; referralFlagCount: number }>();
    for (const c of casesWithContext) {
      let r = regionTotals.get(c.region);
      if (!r) {
        r = { region: c.region, count: 0, referralFlagCount: 0 };
        regionTotals.set(c.region, r);
      }
      r.count += 1;
      if (c.referralFlag) r.referralFlagCount += 1;
    }

    return {
      regions: [...regionTotals.values()].sort((a, b) => b.count - a.count),
      cases: casesWithContext,
    };
  }
}
