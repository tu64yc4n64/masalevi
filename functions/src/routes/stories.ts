import { Router } from 'express';

import { requireAuth, AuthenticatedRequest } from '../auth/middleware';
import {
  createStory,
  deleteStory,
  getStoryById,
  listStories,
  setStoryFavorite,
} from '../db/stories';

export const storiesRouter = Router();

storiesRouter.use(requireAuth);

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

storiesRouter.delete('/:storyId', async (req: AuthenticatedRequest, res) => {
  const storyId = String(req.params.storyId || '');
  await deleteStory(req.auth!.userId, storyId);
  res.status(200).json({ ok: true });
});

storiesRouter.get('/:storyId/audio', async (req: AuthenticatedRequest, res) => {
  const storyId = String(req.params.storyId || '');
  const story = await getStoryById(req.auth!.userId, storyId);
  if (!story?.audio_data_base64) {
    res.status(404).json({ error: 'Masal sesi bulunamadi.' });
    return;
  }

  const buffer = Buffer.from(story.audio_data_base64, 'base64');
  res.setHeader('Content-Type', 'audio/mpeg');
  res.setHeader('Cache-Control', 'private, max-age=3600');
  res.status(200).send(buffer);
});
