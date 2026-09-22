import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { GeminiClient } from '../gemini/gemini-client';

// Demo account credentials — see README for the sign-in demo flow. Passwords
// come from the environment, not the source tree, so they're never committed.
const DEMO_USERNAME = 'demo';
const DEMO_PASSWORD = requireEnv('DEMO_PASSWORD');

// Overseeing-institution admin account — sees unanonymized case data, gated
// by the admin dashboard on the mobile app. Not self-registerable.
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = requireEnv('ADMIN_PASSWORD');

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `${name} is not set. Copy .env.example to .env and set it before running the seed script.`,
    );
  }
  return value;
}

interface ParsedDoc {
  id: string;
  title: string;
  jurisdiction: string;
  sourceUrl: string | null;
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

  return { id: meta.id, title: meta.title, jurisdiction: meta.jurisdiction, sourceUrl: meta.source_url ?? null, chunks };
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
          sourceUrl: doc.sourceUrl,
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
      closedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
      resolutionNote:
        'A neutral elder from a neighboring village walked the boundary with both farmers and the original thorn hedge line. Both agreed to restore the fence to that line and mark it with new boundary stones. No further dispute reported.',
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
    {
      id: 'demo-case-4',
      caseType: 'Neighbor dispute',
      parties: [{ role: 'Complainant' }, { role: 'Neighbor family' }],
      description:
        'Two households have disputed access to grazing land for over two years. The complainant says that during a confrontation at the disputed boundary last week, the neighbor\'s son struck the complainant\'s brother with a farm tool, and the brother later died from his injuries at the general hospital. The complainant came to the mediator to have the land dispute\'s history formally recorded for the police investigation, not for further mediation, since a death is now involved. The mediator explained that this matter cannot be mediated and must go directly to police.',
      location: 'Katsina, Nigeria',
      referralFlag: true,
      referralReason: 'A death resulted from the underlying dispute. Refer directly to police, do not continue mediation.',
    },
    {
      id: 'demo-case-5',
      caseType: 'Other',
      parties: [{ role: 'Complainant' }, { role: 'Accused' }],
      description:
        'A young woman reported that a man from a neighboring compound raped her while she was returning from the market in the evening. She approached the mediator because the two families have an ongoing land dispute the mediator was already handling, and she was unsure where else to report it at the time. The mediator did not discuss the incident further and directed her immediately to the nearest police station and a health facility for care, noting that a criminal matter of this kind is entirely outside mediation\'s scope.',
      location: 'Sokoto, Nigeria',
      referralFlag: true,
      referralReason: 'Alleged rape. Criminal matter, refer immediately to police, mediation does not apply.',
    },
    {
      id: 'demo-case-6',
      caseType: 'Debt / property',
      parties: [{ role: 'Farmer' }, { role: 'Herder' }],
      description:
        'A herder\'s cattle strayed into a farmer\'s groundnut field overnight and destroyed roughly half an acre of the crop ahead of harvest. Both parties agree the herd owner is responsible under the long-standing local custom of compensating for crop damage, but disagree on the value: the farmer wants compensation based on the expected market price at harvest, while the herder is offering a flat sum based on the damaged area. The village head\'s office referred them to the mediator to agree on a fair figure before the disagreement escalates, as has happened between other households in the area. Both parties brought a neutral farmer from a neighboring village to help estimate the loss.',
      location: 'Jos, Nigeria',
      referralFlag: false,
      referralReason: null,
      closedAt: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000),
      resolutionNote:
        'Settled on a compensation figure between the farmer\'s asking price and the herder\'s initial offer, based on the neutral farmer\'s estimate of the damaged area. Herder paid in full at the session.',
    },
    {
      id: 'demo-case-7',
      caseType: 'Domestic / marital',
      parties: [{ role: 'Husband\'s family' }, { role: 'Wife\'s family' }],
      description:
        'A marriage ended after four years without children, and the wife\'s family has approached the husband\'s family to formally end the union under customary law. The husband\'s family is asking for repayment of the bride price and other marriage expenses before agreeing to the separation, while the wife\'s family says most of that amount was already spent on gifts exchanged during the marriage and should not be repaid in full. Both families have a history of intermarriage and want to preserve the relationship between the two households. They approached the mediator jointly, before either side involves the customary court.',
      location: 'Ibadan, Nigeria',
      referralFlag: false,
      referralReason: null,
    },
    {
      id: 'demo-case-8',
      caseType: 'Debt / property',
      parties: [{ role: 'Complainant' }, { role: 'Debtor' }],
      description:
        'A cloth trader gave a fellow trader goods on credit worth about 400,000 naira, to be repaid after the goods were resold, as is common practice among traders in this market. Repayment is now three months overdue. The debtor says sales have been slow since the market\'s access road was blocked for construction, and she has only been able to repay a small portion so far. The complainant says she has her own suppliers to pay and cannot keep waiting indefinitely. Both are members of the same trade association and want to avoid the matter being raised at the association\'s general meeting, which would damage the debtor\'s standing among other traders.',
      location: 'Onitsha, Nigeria',
      referralFlag: false,
      referralReason: null,
    },
    {
      id: 'demo-case-9',
      caseType: 'Other',
      parties: [{ role: 'First son' }, { role: 'Second son' }],
      description:
        'Following the death of a compound head, two of his sons each claim they are the rightful successor under family tradition, one citing his status as first son and the other citing an earlier private understanding with their late father. Extended family members are divided along the same lines, and a planned family meeting to install a successor was cancelled after tempers flared. Because the compound head\'s role in this community is tied to the wider chieftaincy structure recognized by the local government, the mediator explained that a formal succession dispute like this ultimately has to go through the relevant chieftaincy declaration process, though the mediator can still help the family communicate calmly in the meantime.',
      location: 'Benin City, Nigeria',
      referralFlag: true,
      referralReason: 'Formal chieftaincy succession matter governed by state chieftaincy law, outside informal mediation. Direct the family to the local government chieftaincy affairs office.',
    },
    {
      id: 'demo-case-10',
      caseType: 'Neighbor dispute',
      parties: [{ role: 'Complainant' }, { role: 'Neighbor' }],
      description:
        'A neighbor recently began running a large generator most evenings because of frequent power outages, and the noise and fumes reach directly into the complainant\'s bedroom window, disturbing a household member who works night shifts and sleeps during the evening. The generator owner says he has no alternative since he also works from home and needs power for his business. Both sides are willing to compromise but have not been able to agree on a workable schedule on their own. This is the first time either party has sought help with the disagreement.',
      location: 'Lagos, Nigeria',
      referralFlag: false,
      referralReason: null,
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
        closedAt: (ex as { closedAt?: Date }).closedAt ?? undefined,
        resolutionNote: (ex as { resolutionNote?: string }).resolutionNote ?? undefined,
      },
      update: {
        caseType: ex.caseType,
        description: ex.description,
        location: ex.location,
        referralFlag: ex.referralFlag,
        referralReason: ex.referralReason ?? undefined,
        closedAt: (ex as { closedAt?: Date }).closedAt ?? null,
        resolutionNote: (ex as { resolutionNote?: string }).resolutionNote ?? null,
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
  // Not meant to be signed into — only exists to give the admin dashboard a
  // realistic geographic spread, so it reuses the demo account's password.
  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 10);
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
