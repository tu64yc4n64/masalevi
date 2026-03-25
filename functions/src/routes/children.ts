import { Router } from 'express';

import { requireAuth, AuthenticatedRequest } from '../auth/middleware';
import { getChild, listChildren, upsertChild } from '../db/children';

export const childrenRouter = Router();

childrenRouter.use(requireAuth);

childrenRouter.get('/', async (req: AuthenticatedRequest, res) => {
  const children = await listChildren(req.auth!.userId);
  res.status(200).json({ children });
});

childrenRouter.get('/:childId', async (req: AuthenticatedRequest, res) => {
  const childId = String(req.params.childId || '');
  const child = await getChild(req.auth!.userId, childId);
  if (!child) {
    res.status(404).json({ error: 'Cocuk bulunamadi.' });
    return;
  }
  res.status(200).json({ child });
});

childrenRouter.post('/', async (req: AuthenticatedRequest, res) => {
  const body = req.body || {};
  const child = await upsertChild(req.auth!.userId, {
    id: String(body.id || ''),
    name: String(body.name || ''),
    age: Number(body.age || 5),
    gender: String(body.gender || 'other'),
    interests: Array.isArray(body.interests)
        ? body.interests.map((value: unknown) => String(value))
        : [],
    emoji_avatar: String(body.emojiAvatar || '🙂'),
    preferred_theme: body.preferredTheme ? String(body.preferredTheme) : null,
    preferred_value: body.preferredValue ? String(body.preferredValue) : null,
    selected_voice_id: String(body.selectedVoiceId || 'sevgi_teyze'),
  });
  res.status(200).json({ child });
});

childrenRouter.put('/:childId', async (req: AuthenticatedRequest, res) => {
  const body = req.body || {};
  const childId = String(req.params.childId || '');
  const child = await upsertChild(req.auth!.userId, {
    id: childId,
    name: String(body.name || ''),
    age: Number(body.age || 5),
    gender: String(body.gender || 'other'),
    interests: Array.isArray(body.interests)
        ? body.interests.map((value: unknown) => String(value))
        : [],
    emoji_avatar: String(body.emojiAvatar || '🙂'),
    preferred_theme: body.preferredTheme ? String(body.preferredTheme) : null,
    preferred_value: body.preferredValue ? String(body.preferredValue) : null,
    selected_voice_id: String(body.selectedVoiceId || 'sevgi_teyze'),
  });
  res.status(200).json({ child });
});
