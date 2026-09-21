import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { GeminiClient } from '../gemini/gemini-client';

// Demo account credentials — see README for the sign-in demo flow.
const DEMO_USERNAME = 'demo';
const DEMO_PASSWORD = 'password123';

// Overseeing-institution admin account — sees unanonymized case data, gated
// by the admin dashboard on the mobile app. Not self-registerable.
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';

interface ParsedDoc {
  id: string;
  title: string;
  jurisdiction: string;
  chunks: { section: string; content: string }[];
}

function parseSeedFile(raw: string): ParsedDoc {
  const frontmatterMatch = raw.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!frontmatterMatch) {
    throw new Error('Seed file missing --- frontmatter block');
  }
  const [, frontmatter, body] = frontmatterMatch;
  const meta: Record<string, string> = {};
  for (const line of frontmatter.split('\n')) {
    const [key, ...rest] = line.split(':');
    if (key) meta[key.trim()] = rest.join(':').trim();
  }

  const chunks: { section: string; content: string }[] = [];
  const sectionMatches = body.split(/\n(?=## )/g);
  for (const block of sectionMatches) {
    const headingMatch = block.match(/^## (.+)\n([\s\S]*)$/);
    if (!headingMatch) continue; // skips the placeholder-disclaimer preamble before the first "## "
    const [, section, content] = headingMatch;
    chunks.push({ section: section.trim(), content: content.trim() });
  }

  return { id: meta.id, title: meta.title, jurisdiction: meta.jurisdiction, chunks };
}

async function main() {
  const prisma = new PrismaClient();
  const gemini = new GeminiClient(
    process.env.GEMINI_API_KEY ?? '',
    process.env.GEMINI_EMBEDDING_MODEL ?? 'gemini-embedding-001',
    process.env.GEMINI_GENERATION_MODEL ?? 'gemini-2.5-flash',
  );

  const seedDir = path.join(__dirname, '..', '..', 'seed_data');
  const files = fs.readdirSync(seedDir).filter((f) => f.endsWith('.txt'));

  console.log(`Found ${files.length} seed documents in ${seedDir}`);

  await prisma.documentChunk.deleteMany({});

  let total = 0;
  for (const file of files) {
    const raw = fs.readFileSync(path.join(seedDir, file), 'utf-8');
    const doc = parseSeedFile(raw);
    console.log(`  - ${doc.title} (${doc.chunks.length} sections)`);

    for (const chunk of doc.chunks) {
      const embedding = await gemini.embed(`${doc.title} — ${chunk.section}\n${chunk.content}`);
      const id = `${doc.id}__${chunk.section}`.replace(/[^a-zA-Z0-9_]+/g, '_').slice(0, 190);

      await prisma.documentChunk.create({
        data: {
          id,
          documentId: doc.id,
          documentTitle: doc.title,
          jurisdiction: doc.jurisdiction,
          section: chunk.section,
          content: chunk.content,
          embedding,
        },
      });
      total += 1;
    }
  }

  console.log(`Seeded ${total} document chunks with embeddings.`);

  await seedExampleCases(prisma);
  await seedAdminAccount(prisma);
  await seedDashboardDemoData(prisma);

  await prisma.$disconnect();
}

async function seedAdminAccount(prisma: PrismaClient) {
  const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, 10);
  await prisma.mediator.upsert({
    where: { id: 'admin-1' },
    create: {
      id: 'admin-1',
      username: ADMIN_USERNAME,
      passwordHash,
      fullName: 'Ministry of Justice ADR Desk',
      country: 'Nigeria',
      region: 'Federal',
      locality: 'Abuja',
      role: 'admin',
    },
    update: { username: ADMIN_USERNAME, passwordHash, fullName: 'Ministry of Justice ADR Desk', role: 'admin' },
  });
  console.log(`Seeded admin account — sign in with username "${ADMIN_USERNAME}" / password "${ADMIN_PASSWORD}".`);
}

async function seedExampleCases(prisma: PrismaClient) {
  const mediatorId = 'demo-mediator-1';
  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 10);
  await prisma.mediator.upsert({
    where: { id: mediatorId },
    create: {
      id: mediatorId,
      username: DEMO_USERNAME,
      passwordHash,
      fullName: 'Demo Mediator',
      country: 'Nigeria',
      region: 'Kaduna State',
      locality: 'Kaduna',
    },
    update: {
      username: DEMO_USERNAME,
      passwordHash,
      country: 'Nigeria',
      region: 'Kaduna State',
      locality: 'Kaduna',
    },
  });
  console.log(`Seeded demo account — sign in with username "${DEMO_USERNAME}" / password "${DEMO_PASSWORD}".`);

  const examples = [
    {
      id: 'demo-case-1',
      caseType: 'Land boundary',
      parties: [{ role: 'Complainant' }, { role: 'Neighbor' }],
      description:
        'Two neighboring farmers disagree on where the boundary between their unregistered plots lies after a fence was moved during the last planting season.',
      location: 'Kaduna, Nigeria',
      referralFlag: false,
      referralReason: null,
    },
    {
      id: 'demo-case-2',
      caseType: 'Family / inheritance',
      parties: [{ role: 'Widow' }, { role: 'Deceased’s brother' }],
      description:
        'A widow says her late husband’s brother is claiming the family land and threatened her when she refused to leave the homestead.',
      location: 'Zaria, Nigeria',
      referralFlag: true,
      referralReason: 'Threat mentioned alongside a land/inheritance dispute — escalating conflict, refer before continuing mediation.',
    },
    {
      id: 'demo-case-3',
      caseType: 'Neighbor dispute',
      parties: [{ role: 'Complainant' }, { role: 'Neighbor' }],
      description:
        'This is the third time these two neighbors have brought the same water-access disagreement to mediation this year.',
      location: 'Enugu, Nigeria',
      referralFlag: true,
      referralReason: 'Repeat dispute between the same parties — mediation is not resolving the underlying issue.',
    },
  ];

  for (const ex of examples) {
    await prisma.case.upsert({
      where: { id: ex.id },
      create: {
        id: ex.id,
        mediatorId,
        caseType: ex.caseType,
        parties: ex.parties,
        description: ex.description,
        location: ex.location,
        createdAt: new Date(),
        syncedAt: new Date(),
        referralFlag: ex.referralFlag,
        referralReason: ex.referralReason ?? undefined,
      },
      update: {
        caseType: ex.caseType,
        description: ex.description,
        location: ex.location,
        referralFlag: ex.referralFlag,
        referralReason: ex.referralReason ?? undefined,
      },
    });
  }
  console.log(`Seeded ${examples.length} example cases for mediator "${mediatorId}".`);
}

/**
 * Extra mediators/cases across several Nigerian states, purely so the admin
 * case-overview dashboard has a realistic geographic spread to show instead
 * of a single data point. Dated within the last 30 days so they count toward
 * the "recent" escalation signal. Confined to Nigeria only — see README.
 */
async function seedDashboardDemoData(prisma: PrismaClient) {
  // Remove the old Kenya-based demo mediators/cases from a prior version of
  // this seed script — the project is now scoped to Nigeria only.
  const oldMediatorIds = ['dash-mediator-nairobi', 'dash-mediator-mombasa', 'dash-mediator-lagos', 'dash-mediator-kano'];
  const oldCaseIds = ['dash-case-1', 'dash-case-2', 'dash-case-3', 'dash-case-4', 'dash-case-5', 'dash-case-6', 'dash-case-7', 'dash-case-8', 'dash-case-9'];
  await prisma.case.deleteMany({ where: { id: { in: oldCaseIds } } });
  await prisma.mediator.deleteMany({ where: { id: { in: oldMediatorIds } } });

  const passwordHash = await bcrypt.hash('password123', 10);
  const daysAgo = (n: number) => new Date(Date.now() - n * 24 * 60 * 60 * 1000);

  const mediators = [
    { id: 'dash-mediator-lagos', username: 'dash_lagos', fullName: 'Lagos Mediator', country: 'Nigeria', region: 'Lagos State', locality: 'Ikeja' },
    { id: 'dash-mediator-kano', username: 'dash_kano', fullName: 'Kano Mediator', country: 'Nigeria', region: 'Kano State', locality: 'Kano Municipal' },
    { id: 'dash-mediator-rivers', username: 'dash_rivers', fullName: 'Rivers Mediator', country: 'Nigeria', region: 'Rivers State', locality: 'Port Harcourt' },
    { id: 'dash-mediator-enugu', username: 'dash_enugu', fullName: 'Enugu Mediator', country: 'Nigeria', region: 'Enugu State', locality: 'Enugu' },
  ];
  for (const m of mediators) {
    await prisma.mediator.upsert({
      where: { id: m.id },
      create: { ...m, passwordHash },
      update: {},
    });
  }

  interface DashCase {
    id: string;
    mediatorId: string;
    caseType: string;
    location: string;
    daysAgo: number;
    referralFlag: boolean;
  }
  const cases: DashCase[] = [
    // Lagos: high recent tension (2 escalating cases)
    { id: 'dash-case-lagos-1', mediatorId: 'dash-mediator-lagos', caseType: 'Land boundary', location: 'Ikeja, Lagos', daysAgo: 4, referralFlag: true },
    { id: 'dash-case-lagos-2', mediatorId: 'dash-mediator-lagos', caseType: 'Neighbor dispute', location: 'Ikeja, Lagos', daysAgo: 12, referralFlag: true },
    { id: 'dash-case-lagos-3', mediatorId: 'dash-mediator-lagos', caseType: 'Domestic / marital', location: 'Ikeja, Lagos', daysAgo: 20, referralFlag: false },
    // Kano: high recent tension
    { id: 'dash-case-kano-1', mediatorId: 'dash-mediator-kano', caseType: 'Neighbor dispute', location: 'Kano Municipal', daysAgo: 2, referralFlag: true },
    { id: 'dash-case-kano-2', mediatorId: 'dash-mediator-kano', caseType: 'Neighbor dispute', location: 'Kano Municipal', daysAgo: 9, referralFlag: true },
    // Rivers: quiet
    { id: 'dash-case-rivers-1', mediatorId: 'dash-mediator-rivers', caseType: 'Family / inheritance', location: 'Port Harcourt', daysAgo: 15, referralFlag: false },
    { id: 'dash-case-rivers-2', mediatorId: 'dash-mediator-rivers', caseType: 'Debt / property', location: 'Port Harcourt', daysAgo: 25, referralFlag: false },
    // Enugu: one escalating
    { id: 'dash-case-enugu-1', mediatorId: 'dash-mediator-enugu', caseType: 'Land boundary', location: 'Enugu', daysAgo: 6, referralFlag: true },
    { id: 'dash-case-enugu-2', mediatorId: 'dash-mediator-enugu', caseType: 'Neighbor dispute', location: 'Enugu', daysAgo: 18, referralFlag: false },
  ];

  for (const c of cases) {
    await prisma.case.upsert({
      where: { id: c.id },
      create: {
        id: c.id,
        mediatorId: c.mediatorId,
        caseType: c.caseType,
        parties: [{ role: 'Complainant' }, { role: 'Neighbor' }],
        description: 'Placeholder demo case seeded for the admin case-overview dashboard.',
        location: c.location,
        createdAt: daysAgo(c.daysAgo),
        syncedAt: daysAgo(c.daysAgo),
        referralFlag: c.referralFlag,
        referralReason: c.referralFlag ? 'Seeded demo escalation signal.' : undefined,
      },
      update: {},
    });
  }
  console.log(`Seeded ${mediators.length} more mediators / ${cases.length} cases across Nigerian states for the admin dashboard demo.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
