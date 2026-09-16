import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

export interface ReferralCategory {
  id: string;
  label: string;
  reason: string;
  suggestedNextStep: string;
  keywords: string[];
}

export interface ReferralCheckResult {
  flagged: boolean;
  categoryId?: string;
  categoryLabel?: string;
  reason?: string;
  suggestedNextStep?: string;
}

@Injectable()
export class ReferralService {
  private readonly categories: ReferralCategory[];

  constructor() {
    const raw = fs.readFileSync(path.join(__dirname, 'referral-categories.json'), 'utf-8');
    this.categories = JSON.parse(raw).categories;
  }

  getCategories(): ReferralCategory[] {
    return this.categories;
  }

  /** Plain keyword match against the explicit category list — same rule a mediator can read and edit. */
  checkKeywords(description: string): ReferralCheckResult {
    const text = description.toLowerCase();
    for (const category of this.categories) {
      const hit = category.keywords.find((kw) => text.includes(kw.toLowerCase()));
      if (hit) {
        return {
          flagged: true,
          categoryId: category.id,
          categoryLabel: category.label,
          reason: category.reason,
          suggestedNextStep: category.suggestedNextStep,
        };
      }
    }
    return { flagged: false };
  }
}
