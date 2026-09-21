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

  // Full wipe — this is a hackathon demo database, not real user data, so a
  // clean reseed (rather than incremental upserts) is the simplest way to
  // guarantee every record is current and confined to Nigeria.
  await prisma.case.deleteMany({});
  await prisma.mediator.deleteMany({});
  await prisma.documentChunk.deleteMany({});
  console.log('Cleared all existing cases, mediators, and document chunks.');

  const seedDir = path.join(__dirname, '..', '..', 'seed_data');
  const files = fs.readdirSync(seedDir).filter((f) => f.endsWith('.txt'));

  console.log(`Found ${files.length} seed documents in ${seedDir}`);

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
        'The complainant, a maize farmer, says his neighbor moved a boundary fence roughly two meters onto his plot during land preparation in early March. Both farmers have worked adjoining unregistered plots inherited from their fathers for over fifteen years, with no formal survey on either side. The neighbor says he only restored the fence to where his late father originally set it, and disputes the complainant\'s version of the boundary. Village elders inspected the site and found no clear boundary markers, only an old thorn hedge partially grown over. Both parties agreed to mediation rather than involve the Land Registry, since neither holds a certificate of occupancy and a formal survey would be costly. This is their first time bringing the dispute to mediation.',
      location: 'Kaduna, Nigeria',
      referralFlag: false,
      referralReason: null,
    },
    {
      id: 'demo-case-2',
      caseType: 'Family / inheritance',
      parties: [{ role: 'Widow' }, { role: 'Deceased’s brother' }],
      description:
        'The widow, in her early fifties, says her late husband\'s younger brother arrived at the family homestead with three other relatives, informing her the land and house now belonged to him under family custom since her husband died without a will. She has lived on the land for over twenty years and has four children still in school. When she refused to leave, the brother-in-law reportedly raised his voice, pushed past her into the compound, and said he would return with more relatives if she had not packed by the end of the month. No physical injury occurred, but she is frightened and has not returned to the homestead alone since. She wants to know her rights to remain and whether the threat itself should be reported before mediation continues.',
      location: 'Zaria, Nigeria',
      referralFlag: true,
      referralReason: 'Threat mentioned alongside a land/inheritance dispute. Escalating conflict, refer before continuing mediation.',
    },
    {
      id: 'demo-case-3',
      caseType: 'Neighbor dispute',
      parties: [{ role: 'Complainant' }, { role: 'Neighbor' }],
      description:
        'Two neighboring households have disputed access to a shared borehole for over a year. The complainant says the other family began fetching water at odd hours and, on two occasions, blocked the shared path with farm produce to discourage use. This is the third time the same two parties have brought this exact dispute to mediation, most recently in June and again in August, each time reaching a verbal agreement on shared hours that broke down within weeks. The complainant says the other party stopped honoring the June agreement almost immediately. Both households depend on the borehole since the nearest alternative source is over a kilometer away. Given the repeat pattern, the mediator is uncertain informal mediation alone will resolve the underlying tension this time.',
      location: 'Enugu, Nigeria',
      referralFlag: true,
      referralReason: 'Repeat dispute between the same parties. Mediation is not resolving the underlying issue.',
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
