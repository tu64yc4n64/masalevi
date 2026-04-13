import { Router } from 'express';

import { requireAuth, AuthenticatedRequest } from '../auth/middleware';
import {
  createStory,
  deleteStory,
  getCachedStoryAudio,
  getStoryById,
  listStories,
  setStoryFavorite,
  setStoryVoice,
  upsertStoryAudioCache,
} from '../db/stories';
import { synthesizeSpeech } from '../tts/provider';
import { CUSTOM_USER_VOICE_ID } from '../tts/constants';

export const storiesRouter = Router();
const customAudioGenerationJobs = new Map<string, Promise<void>>();

storiesRouter.use(requireAuth);

function customAudioJobKey(storyId: string, voiceId: string): string {
  return `${storyId}:${voiceId}`;
}

function ensureCustomAudioGeneration(input: {
  storyId: string;
  voiceId: string;
  userId: string;
  text: string;
}): void {
  const key = customAudioJobKey(input.storyId, input.voiceId);
  if (customAudioGenerationJobs.has(key)) {
    return;
  }

  const job = (async () => {
    const audioDataBase64 = await synthesizeSpeech({
      text: input.text,
      selectedVoiceId: input.voiceId,
      userId: input.userId,
    });

    if (!audioDataBase64) {
      throw new Error('Masal sesi uretilemedi.');
    }

    await upsertStoryAudioCache({
      storyId: input.storyId,
      voiceId: input.voiceId,
      audioDataBase64,
    });
  })()
      .catch((error) => {
        console.error(
          '[custom-voice] background generation failed',
          JSON.stringify({
            storyId: input.storyId,
            voiceId: input.voiceId,
            userId: input.userId,
            error: error instanceof Error ? error.message : String(error),
          }),
        );
      })
      .finally(() => {
        customAudioGenerationJobs.delete(key);
      });

  customAudioGenerationJobs.set(key, job);
}

storiesRouter.get('/', async (req: AuthenticatedRequest, res) => {
  const stories = (await listStories(req.auth!.userId)).map((story) => ({
    ...story,
    audio_url: story.audio_data_base64 ? `/stories/${story.id}/audio` : story.audio_url,
  }));
  res.status(200).json({ stories });
});

storiesRouter.get('/:storyId', async (req: AuthenticatedRequest, res) => {
  const storyId = String(req.params.storyId || '');
  const story = await getStoryById(req.auth!.userId, storyId);
  if (!story) {
    res.status(404).json({ error: 'Masal bulunamadi.' });
    return;
  }
  res.status(200).json({
    story: {
      ...story,
      audio_url: story.audio_data_base64 ? `/stories/${story.id}/audio` : story.audio_url,
    },
  });
});

storiesRouter.post('/', async (req: AuthenticatedRequest, res) => {
  const story = await createStory({
    userId: req.auth!.userId,
    childId: String(req.body?.childId || ''),
    title: String(req.body?.title || 'Masal'),
    content: String(req.body?.content || ''),
  });
  res.status(200).json({
    story: {
      ...story,
      audio_url: story.audio_data_base64 ? `/stories/${story.id}/audio` : story.audio_url,
    },
  });
});

storiesRouter.patch('/:storyId/favorite', async (req: AuthenticatedRequest, res) => {
  const storyId = String(req.params.storyId || '');
  await setStoryFavorite(
    req.auth!.userId,
    storyId,
    Boolean(req.body?.isFavorite),
  );
  res.status(200).json({ ok: true });
});

storiesRouter.patch('/:storyId/voice', async (req: AuthenticatedRequest, res) => {
  const storyId = String(req.params.storyId || '');
  const voiceId = String(req.body?.voiceId || '').trim();
  if (!voiceId) {
    res.status(400).json({ error: 'Ses secimi gerekli.' });
    return;
  }
  await setStoryVoice(req.auth!.userId, storyId, voiceId);
  res.status(200).json({ ok: true });
});

storiesRouter.delete('/:storyId', async (req: AuthenticatedRequest, res) => {
  const storyId = String(req.params.storyId || '');
  await deleteStory(req.auth!.userId, storyId);
  res.status(200).json({ ok: true });
});

storiesRouter.get('/:storyId/audio', async (req: AuthenticatedRequest, res) => {
  const storyId = String(req.params.storyId || '');
  const story = await getStoryById(req.auth!.userId, storyId);
  if (!story) {
    res.status(404).json({ error: 'Masal bulunamadi.' });
    return;
  }

  const requestedVoiceId = String(req.query.voiceId || '').trim();
  if (requestedVoiceId.length > 0) {
    const cachedAudioDataBase64 = await getCachedStoryAudio(
      story.id,
      requestedVoiceId,
    );
    if (
      cachedAudioDataBase64 == null &&
      requestedVoiceId == CUSTOM_USER_VOICE_ID
    ) {
      ensureCustomAudioGeneration({
        storyId: story.id,
        voiceId: requestedVoiceId,
        userId: req.auth!.userId,
        text: story.content,
      });
      res.status(202).json({ status: 'processing' });
      return;
    }

    const audioDataBase64 =
      cachedAudioDataBase64 ??
      (await synthesizeSpeech({
        text: story.content,
        selectedVoiceId: requestedVoiceId,
        userId: req.auth!.userId,
      }));

    if (!audioDataBase64) {
      res.status(404).json({ error: 'Masal sesi uretilemedi.' });
      return;
    }

    if (cachedAudioDataBase64 == null) {
      await upsertStoryAudioCache({
        storyId: story.id,
        voiceId: requestedVoiceId,
        audioDataBase64,
      });
    }

    const buffer = Buffer.from(audioDataBase64, 'base64');
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Cache-Control', 'private, max-age=31536000');
    res.status(200).send(buffer);
    return;
  }

  if (!story.audio_data_base64) {
    res.status(404).json({ error: 'Masal sesi bulunamadi.' });
    return;
  }

  const buffer = Buffer.from(story.audio_data_base64, 'base64');
  res.setHeader('Content-Type', 'audio/mpeg');
  res.setHeader('Cache-Control', 'private, max-age=3600');
  res.status(200).send(buffer);
});
