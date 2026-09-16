import { GoogleGenAI } from '@google/genai';

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
    const response = await this.client.models.embedContent({
      model: this.embeddingModel,
      contents: [text],
    });
    const values = response.embeddings?.[0]?.values;
    if (!values) {
      throw new Error('Gemini embedContent returned no embedding values.');
    }
    return values;
  }

  async generate(prompt: string): Promise<string> {
    const response = await this.client.models.generateContent({
      model: this.generationModel,
      contents: prompt,
    });
    return response.text ?? '';
  }

  /** Same as generate(), but also gives the model the actual audio recording(s) (not just their transcript). */
  async generateWithAudio(prompt: string, audioClips: { buffer: Buffer; mimeType: string }[]): Promise<string> {
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
  }
}
