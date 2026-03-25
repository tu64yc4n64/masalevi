const FREE_STORY_LIMIT = 20;
const TRIAL_STORY_LIMIT = 50;
const PREMIUM_STORY_LIMIT = 200;

export function nextResetDate(from: Date): Date {
  // Bir sonraki ayın 1. günü.
  return new Date(from.getFullYear(), from.getMonth() + 1, 1, 0, 0, 0, 0);
}

export function shouldReset(now: Date, resetDate: Date): boolean {
  return now.getTime() > resetDate.getTime();
}

export function canGenerateStory(params: {
  isPremium: boolean;
  isTrialActive: boolean;
  role: 'user' | 'admin' | 'owner';
  storyCount: number;
}): boolean {
  if (params.role === 'admin' || params.role === 'owner') return true;
  if (params.isPremium) return params.storyCount < PREMIUM_STORY_LIMIT;
  if (params.isTrialActive) return params.storyCount < TRIAL_STORY_LIMIT;
  return params.storyCount < FREE_STORY_LIMIT;
}

export { FREE_STORY_LIMIT, TRIAL_STORY_LIMIT, PREMIUM_STORY_LIMIT };
