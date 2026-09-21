import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReferralService } from '../referral/referral.service';
import { GeminiClient } from '../gemini/gemini-client';
import { cosineSimilarity } from './similarity';

export interface AdvisoryCitation {
  documentId: string;
  documentTitle: string;
  jurisdiction: string;
  section: string | null;
  sourceUrl: string | null;
  excerpt: string;
  similarity: number;
}

export interface AdvisoryResult {
  summary: string;
  citations: AdvisoryCitation[];
  suggestsReferral: boolean;
  referralNote: string | null;
  generatedAt: string;
}

const TOP_K = 4;
// Below this cosine-similarity, we don't trust the match enough to let the model answer from it.
const SIMILARITY_FLOOR = 0.55;

@Injectable()
export class AdvisoryService {
  private readonly gemini: GeminiClient;

  constructor(
    private readonly prisma: PrismaService,
    private readonly referralService: ReferralService,
  ) {
    this.gemini = new GeminiClient(
      process.env.GEMINI_API_KEY ?? '',
      process.env.GEMINI_EMBEDDING_MODEL ?? 'gemini-embedding-001',
      process.env.GEMINI_GENERATION_MODEL ?? 'gemini-2.5-flash',
    );
  }

  async query(
    description: string,
    caseId?: string,
    mediatorId?: string,
    audioClips: { buffer: Buffer; mimeType: string }[] = [],
  ): Promise<AdvisoryResult> {
    const queryEmbedding = await this.gemini.embed(description);

    const chunks = await this.prisma.documentChunk.findMany();
    const ranked = chunks
      .map((c) => ({ ...c, similarity: cosineSimilarity(queryEmbedding, c.embedding) }))
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, TOP_K);

    const relevant = ranked.filter((r) => r.similarity >= SIMILARITY_FLOOR);

    const keywordCheck = this.referralService.checkKeywords(description);

    if (relevant.length === 0) {
      const result: AdvisoryResult = {
        summary:
          'No excerpt in the seeded corpus is close enough to this case to cite with confidence. ' +
          'Do not answer from general knowledge. Ask a supervising mediator or check the full statute directly.',
        citations: [],
        suggestsReferral: keywordCheck.flagged,
        referralNote: keywordCheck.flagged ? keywordCheck.reason ?? null : null,
        generatedAt: new Date().toISOString(),
      };
      await this.maybePersist(caseId, mediatorId, result);
      return result;
    }

    const categoriesBlock = this.referralService
      .getCategories()
      .map((c) => `- ${c.label}: ${c.reason}`)
      .join('\n');

    const excerptsBlock = relevant
      .map(
        (r, i) =>
          `[Excerpt ${i + 1}] Document: "${r.documentTitle}" (${r.jurisdiction})${
            r.section ? `, Section: ${r.section}` : ''
          }\n${r.content}`,
      )
      .join('\n\n');

    const prompt = `You are an advisory assistant for community dispute mediators in Nigeria. The mediator
already knows the facts of their own case — do not summarize or restate the case description back to them.
Your job is to tell them what to DO NEXT: concrete, practical next steps for handling this specific
mediation, in plain language.
You must ground every legal claim in the excerpts below only. Never use outside/general legal knowledge.
For every legal claim, cite the excerpt's document title and section, e.g. "(Land Use Act, Section 6)".
If the excerpts don't clearly support a next step, say so plainly instead of guessing.
${
  audioClips.length > 0
    ? `${audioClips.length > 1 ? `${audioClips.length} audio recordings` : 'An audio recording'} of the case ${audioClips.length > 1 ? 'are' : 'is'} attached alongside the transcribed text below — listen to them for tone, urgency, or detail the transcription may have missed, and factor that into your guidance (but still only cite the written excerpts, never invent a citation from the audio).\n`
    : ''
}Give 2-4 concrete next steps as short sentences (e.g. what to verify, who to involve, what process to
propose to the parties). This is a suggestion for the mediator to weigh, never a ruling or instruction
they must follow.

CASE DESCRIPTION:
${description}

EXCERPTS:
${excerptsBlock}

REFERRAL CATEGORIES (for your second task only — do not treat this list as legal text to cite):
${categoriesBlock}

Respond in exactly this format:
GUIDANCE: <your cited next-step recommendations>
REFERRAL: <YES or NO>
REFERRAL_NOTE: <one sentence, only if REFERRAL is YES, else "none">`;

    const raw =
      audioClips.length > 0
        ? await this.gemini.generateWithAudio(prompt, audioClips)
        : await this.gemini.generate(prompt);
    const parsed = this.parseModelResponse(raw);

    const result: AdvisoryResult = {
      summary: parsed.summary,
      citations: relevant.map((r) => ({
        documentId: r.documentId,
        documentTitle: r.documentTitle,
        jurisdiction: r.jurisdiction,
        section: r.section,
        sourceUrl: r.sourceUrl,
        excerpt: r.content,
        similarity: r.similarity,
      })),
      suggestsReferral: parsed.referral || keywordCheck.flagged,
      referralNote: parsed.referralNote ?? (keywordCheck.flagged ? keywordCheck.reason ?? null : null),
      generatedAt: new Date().toISOString(),
    };

    await this.maybePersist(caseId, mediatorId, result);
    return result;
  }

  private parseModelResponse(raw: string): { summary: string; referral: boolean; referralNote: string | null } {
    const summaryMatch = raw.match(/GUIDANCE:\s*([\s\S]*?)(?:\nREFERRAL:|$)/i);
    const referralMatch = raw.match(/REFERRAL:\s*(YES|NO)/i);
    const noteMatch = raw.match(/REFERRAL_NOTE:\s*(.*)/i);
    return {
      summary: summaryMatch ? summaryMatch[1].trim() : raw.trim(),
      referral: referralMatch ? referralMatch[1].toUpperCase() === 'YES' : false,
      referralNote: noteMatch && noteMatch[1].trim().toLowerCase() !== 'none' ? noteMatch[1].trim() : null,
    };
  }

  private async maybePersist(caseId: string | undefined, mediatorId: string | undefined, result: AdvisoryResult) {
    if (!caseId) return;
    const existing = await this.prisma.case.findUnique({ where: { id: caseId } });
    if (!existing) return;
    // Don't let a lookup write advisory data onto a case synced under a different account.
    if (mediatorId && existing.mediatorId !== mediatorId) return;
    await this.prisma.case.update({
      where: { id: caseId },
      data: {
        advisoryResponse: result as any,
        referralFlag: existing.referralFlag || result.suggestsReferral,
        referralReason: existing.referralReason ?? result.referralNote ?? undefined,
      },
    });
  }
}
