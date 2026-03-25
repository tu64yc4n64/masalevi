import { AI_PROVIDER } from '../config';
import { sanitizeStoryRequest } from '../security/sanitize';
import { getUserRole } from '../security/admin';
import { buildStoryPrompt } from '../prompt/promptTemplate';
import { canGenerateStory, nextResetDate, shouldReset } from './rateLimit';
import { generateStoryWithGroq } from '../aiProviders/groq';
import { generateStoryWithClaude } from '../aiProviders/claude';
import { AuthenticatedRequest } from '../auth/middleware';
import { createStory } from '../db/stories';
import { getUserById, incrementStoryCount } from '../db/users';
import { synthesizeSpeechWithElevenLabs } from '../tts/elevenlabs';

function parseTitleAndContent(raw: string): { title: string; content: string } {
  const trimmed = raw.trim();
  const lines = trimmed.split('\n').map((l) => l.trim()).filter(Boolean);
  if (lines.length >= 2) {
    return { title: lines[0].slice(0, 80), content: lines.slice(1).join('\n').trim() };
  }
  return { title: 'Masal Evi', content: trimmed };
}

export async function generateStoryHandler(
  req: AuthenticatedRequest,
  res: any,
): Promise<void> {
  try {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }

    if (!req.auth?.userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const uid = req.auth.userId;

    const role = await getUserRole(uid);
    const user = await getUserById(uid);
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    const isPremium = Boolean(user.is_premium);
    const trialEndsAt = user.trial_ends_at;
    const isTrialActive = new Date().getTime() < trialEndsAt.getTime();

    // Rate limit state.
    const storyCount = Number(user.story_count || 0);
    const resetDate = new Date(user.story_reset_date);

    let currentStoryCount = storyCount;
    let currentResetDate = resetDate;
    if (shouldReset(new Date(), currentResetDate)) {
      currentStoryCount = 0;
      currentResetDate = nextResetDate(new Date());
    }

    if (!canGenerateStory({ isPremium, isTrialActive, role, storyCount: currentStoryCount })) {
      res.status(403).json({ error: 'FREE_MONTHLY_LIMIT_REACHED' });
      return;
    }

    const safe = sanitizeStoryRequest(req.body || {});
    const prompt = buildStoryPrompt({
      childName: safe.childName,
      age: safe.age,
      gender: safe.gender,
      theme: safe.theme,
      value: safe.value,
      length: safe.length,
    });

    const provider = AI_PROVIDER;
    const rawStory =
      provider === 'claude'
        ? await generateStoryWithClaude(prompt)
        : await generateStoryWithGroq(prompt);

    const { title, content } = parseTitleAndContent(rawStory);
    const audioDataBase64 = await synthesizeSpeechWithElevenLabs({
      text: content,
      selectedVoiceId: safe.selectedVoiceId,
    });

    const story = await createStory({
      userId: uid,
      childId: safe.childId,
      title,
      content,
      audioDataBase64,
    });

    // Update quota.
    if (role === 'user') {
      await incrementStoryCount(uid);
    }

    res.status(200).json({
      title,
      content,
      storyId: story.id,
      audioUrl: audioDataBase64 != null ? `/stories/${story.id}/audio` : null,
    });
  } catch (e: any) {
    res.status(500).json({ error: e?.message || 'Internal Error' });
  }
}
