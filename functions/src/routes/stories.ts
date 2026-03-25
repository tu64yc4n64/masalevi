import { Router } from 'express';

import { requireAuth, AuthenticatedRequest } from '../auth/middleware';
import { createStory, listStories, setStoryFavorite } from '../db/stories';

export const storiesRouter = Router();

storiesRouter.use(requireAuth);

storiesRouter.get('/', async (req: AuthenticatedRequest, res) => {
  const stories = await listStories(req.auth!.userId);
  res.status(200).json({ stories });
});

storiesRouter.post('/', async (req: AuthenticatedRequest, res) => {
  const story = await createStory({
    userId: req.auth!.userId,
    childId: String(req.body?.childId || ''),
    title: String(req.body?.title || 'Masal'),
    content: String(req.body?.content || ''),
  });
  res.status(200).json({ story });
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
