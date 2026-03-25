import * as adminSdk from 'firebase-admin';

import { AI_PROVIDER } from '../config';
import { sanitizeStoryRequest } from '../security/sanitize';
import { getUserRole } from '../security/admin';
import { buildStoryPrompt } from '../prompt/promptTemplate';
import { canGenerateStory, nextResetDate, shouldReset } from './rateLimit';
import { generateStoryWithGroq } from '../aiProviders/groq';
import { generateStoryWithClaude } from '../aiProviders/claude';

function getBearerToken(req: any): string | null {
  const header = req.get?.('Authorization') || req.headers?.authorization;
  if (!header || typeof header !== 'string') return null;
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return null;
  return token;
}

function parseTitleAndContent(raw: string): { title: string; content: string } {
  const trimmed = raw.trim();
  const lines = trimmed.split('\n').map((l) => l.trim()).filter(Boolean);
  if (lines.length >= 2) {
    return { title: lines[0].slice(0, 80), content: lines.slice(1).join('\n').trim() };
  }
  return { title: 'Masal Evi', content: trimmed };
}

export async function generateStoryHandler(req: any, res: any): Promise<void> {
  try {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }

    const token = getBearerToken(req);
    if (!token) {
      res.status(401).json({ error: 'Missing Authorization Bearer token' });
      return;
    }

    const decoded = await adminSdk.auth().verifyIdToken(token);
    const uid: string = decoded.uid;

    const role = await getUserRole(uid);
    const userDoc = await adminSdk.firestore().collection('users').doc(uid).get();

    const data = userDoc.exists ? userDoc.data() || {} : {};
    const isPremium = Boolean(data.isPremium);
    const trialEndsAtTs = data.trialEndsAt;
    const trialEndsAt =
      trialEndsAtTs && typeof trialEndsAtTs.toDate === 'function'
        ? trialEndsAtTs.toDate()
        : new Date(0);
    const isTrialActive = new Date().getTime() < trialEndsAt.getTime();

    // Rate limit state.
    const storyCount = Number(data.storyCount || 0);
    const resetTs = data.storyResetDate;
    const resetDate =
      resetTs && typeof resetTs.toDate === 'function' ? resetTs.toDate() : new Date();

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

    // Store story (MVP’de istek gelir gelmez kaydet).
    const storyRef = adminSdk.firestore().collection('stories').doc();
    await storyRef.set({
      storyId: storyRef.id,
      userId: uid,
      childId: safe.childId,
      title,
      content,
      audioUrl: null,
      createdAt: adminSdk.firestore.FieldValue.serverTimestamp(),
      isFavorite: false,
    });

    // Update quota.
    if (role === 'user') {
      await adminSdk.firestore().collection('users').doc(uid).set(
        {
          storyCount: currentStoryCount + 1,
          storyResetDate: adminSdk.firestore.Timestamp.fromDate(currentResetDate),
        },
        { merge: true },
      );
    }

    res.status(200).json({ title, content, storyId: storyRef.id });
  } catch (e: any) {
    res.status(500).json({ error: e?.message || 'Internal Error' });
  }
}
