import { GoogleGenAI } from '@google/genai';

const MAX_RETRIES = 3;
const RETRY_BASE_DELAY_MS = 1000;

/**
 * Gemini's free tier intermittently returns 503 "high demand" for a few
 * seconds at a time — genuinely transient, not a code bug (see README). Retry
 * a few times with backoff before giving up, since a mediator tapping "Ask
 * for guidance" shouldn't see a 500 for something that would succeed on a
 * near-immediate retry.
 */
async function withRetry<T>(fn: () => Promise<T>): Promise<T> {
  let lastError: unknown;
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      const status = (err as { status?: number })?.status;
      const retryable = status === 503 || status === 429;
      if (!retryable || attempt === MAX_RETRIES) throw err;
      await new Promise((resolve) => setTimeout(resolve, RETRY_BASE_DELAY_MS * 2 ** attempt));
    }
  }
  throw lastError;
}

/**
 * Thin wrapper around the Gemini SDK shared by the Nest AdvisoryService and the
 * standalone seed script (which runs outside the Nest DI container).
 */
export class GeminiClient {
  private readonly client: GoogleGenAI;
  private readonly embeddingModel: string;
  private readonly generationModel: string;

  constructor(apiKey: string, embeddingModel: string, generationModel: string) {
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not set. Copy backend/.env.example to backend/.env and fill it in.');
    }
    this.client = new GoogleGenAI({ apiKey });
    this.embeddingModel = embeddingModel;
    this.generationModel = generationModel;
  }

  async embed(text: string): Promise<number[]> {
    return withRetry(async () => {
      const response = await this.client.models.embedContent({
        model: this.embeddingModel,
        contents: [text],
      });
      const values = response.embeddings?.[0]?.values;
      if (!values) {
        throw new Error('Gemini embedContent returned no embedding values.');
      }
      return values;
    });
  }

  async generate(prompt: string): Promise<string> {
    return withRetry(async () => {
      const response = await this.client.models.generateContent({
        model: this.generationModel,
        contents: prompt,
      });
      return response.text ?? '';
    });
  }

  /** Same as generate(), but also gives the model the actual audio recording(s) (not just their transcript). */
  async generateWithAudio(prompt: string, audioClips: { buffer: Buffer; mimeType: string }[]): Promise<string> {
    return withRetry(async () => {
      const response = await this.client.models.generateContent({
        model: this.generationModel,
        contents: {
          role: 'user',
          parts: [
            { text: prompt },
            ...audioClips.map((clip) => ({
              inlineData: { mimeType: clip.mimeType, data: clip.buffer.toString('base64') },
            })),
          ],
        },
      });
      return response.text ?? '';
    });
  }
}
