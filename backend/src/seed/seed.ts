import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { GeminiClient } from '../gemini/gemini-client';

// Demo account credentials — see README for the sign-in demo flow.
const DEMO_USERNAME = 'demo';
const DEMO_PASSWORD = 'password123';

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
  await seedDashboardDemoData(prisma);

  await prisma.$disconnect();
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
      country: 'Kenya',
      region: 'Kajiado County',
      locality: 'Kajiado Town',
    },
    update: { username: DEMO_USERNAME, passwordHash },
  });
  console.log(`Seeded demo account — sign in with username "${DEMO_USERNAME}" / password "${DEMO_PASSWORD}".`);

  const examples = [
    {
      id: 'demo-case-1',
      caseType: 'Land boundary',
      parties: [{ role: 'Complainant' }, { role: 'Neighbor' }],
      description:
        'Two neighboring farmers disagree on where the boundary between their unregistered plots lies after a fence was moved during the last planting season.',
      location: 'Kajiado, Kenya',
      referralFlag: false,
      referralReason: null,
    },
    {
      id: 'demo-case-2',
      caseType: 'Family / inheritance',
      parties: [{ role: 'Widow' }, { role: 'Deceased’s brother' }],
      description:
        'A widow says her late husband’s brother is claiming the family land and threatened her when she refused to leave the homestead.',
      location: 'Kisumu, Kenya',
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
      update: {},
    });
  }
  console.log(`Seeded ${examples.length} example cases for mediator "${mediatorId}".`);
}

/**
 * Extra mediators/cases across several regions in both countries, purely so
 * `/stats/aggregate` (the anonymized cross-community tension-signal view)
 * has a realistic geographic spread to show instead of a single data point.
 * Dated within the last 30 days so they count toward the "recent" signal.
 */
async function seedDashboardDemoData(prisma: PrismaClient) {
  const passwordHash = await bcrypt.hash('password123', 10);
  const daysAgo = (n: number) => new Date(Date.now() - n * 24 * 60 * 60 * 1000);

  const mediators = [
    { id: 'dash-mediator-nairobi', username: 'dash_nairobi', fullName: 'Nairobi Mediator', country: 'Kenya', region: 'Nairobi County', locality: 'Kibera' },
    { id: 'dash-mediator-mombasa', username: 'dash_mombasa', fullName: 'Mombasa Mediator', country: 'Kenya', region: 'Mombasa County', locality: 'Nyali' },
    { id: 'dash-mediator-lagos', username: 'dash_lagos', fullName: 'Lagos Mediator', country: 'Nigeria', region: 'Lagos State', locality: 'Ikeja' },
    { id: 'dash-mediator-kano', username: 'dash_kano', fullName: 'Kano Mediator', country: 'Nigeria', region: 'Kano State', locality: 'Kano Municipal' },
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
    // Nairobi: high recent tension (2 escalating cases)
    { id: 'dash-case-1', mediatorId: 'dash-mediator-nairobi', caseType: 'Neighbor dispute', location: 'Kibera, Nairobi', daysAgo: 3, referralFlag: true },
    { id: 'dash-case-2', mediatorId: 'dash-mediator-nairobi', caseType: 'Land boundary', location: 'Kibera, Nairobi', daysAgo: 10, referralFlag: true },
    { id: 'dash-case-3', mediatorId: 'dash-mediator-nairobi', caseType: 'Debt / property', location: 'Kibera, Nairobi', daysAgo: 20, referralFlag: false },
    // Mombasa: quiet
    { id: 'dash-case-4', mediatorId: 'dash-mediator-mombasa', caseType: 'Family / inheritance', location: 'Nyali, Mombasa', daysAgo: 15, referralFlag: false },
    { id: 'dash-case-5', mediatorId: 'dash-mediator-mombasa', caseType: 'Neighbor dispute', location: 'Nyali, Mombasa', daysAgo: 25, referralFlag: false },
    // Lagos: one escalating
    { id: 'dash-case-6', mediatorId: 'dash-mediator-lagos', caseType: 'Land boundary', location: 'Ikeja, Lagos', daysAgo: 5, referralFlag: true },
    { id: 'dash-case-7', mediatorId: 'dash-mediator-lagos', caseType: 'Domestic / marital', location: 'Ikeja, Lagos', daysAgo: 18, referralFlag: false },
    // Kano: high recent tension
    { id: 'dash-case-8', mediatorId: 'dash-mediator-kano', caseType: 'Neighbor dispute', location: 'Kano Municipal', daysAgo: 2, referralFlag: true },
    { id: 'dash-case-9', mediatorId: 'dash-mediator-kano', caseType: 'Neighbor dispute', location: 'Kano Municipal', daysAgo: 8, referralFlag: true },
  ];

  for (const c of cases) {
    await prisma.case.upsert({
      where: { id: c.id },
      create: {
        id: c.id,
        mediatorId: c.mediatorId,
        caseType: c.caseType,
        parties: [{ role: 'Complainant' }, { role: 'Neighbor' }],
        description: 'Placeholder demo case seeded for the aggregate tension-signal dashboard.',
        location: c.location,
        createdAt: daysAgo(c.daysAgo),
        syncedAt: daysAgo(c.daysAgo),
        referralFlag: c.referralFlag,
        referralReason: c.referralFlag ? 'Seeded demo escalation signal.' : undefined,
      },
      update: {},
    });
  }
  console.log(`Seeded ${mediators.length} more mediators / ${cases.length} cases across regions for the dashboard demo.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
