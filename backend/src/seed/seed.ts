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

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
