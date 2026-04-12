import { Router } from 'express';
import { promises as fs } from 'fs';
import path from 'path';

import { requireAdmin, requireAuth, requireOwner, AuthenticatedRequest } from '../auth/middleware';
import {
  getUserById,
  listUsers,
  setUserCustomVoiceSample,
  setUserPremium,
  setUserRole,
} from '../db/users';

export const usersRouter = Router();

const voiceSampleStorageDir = path.resolve(
  process.cwd(),
  'storage',
  'voice_samples',
);

function extensionForMimeType(mimeType: string): string {
  switch (mimeType) {
    case 'audio/wav':
    case 'audio/x-wav':
      return 'wav';
    case 'audio/mp4':
    case 'audio/m4a':
    case 'audio/aac':
    default:
      return 'm4a';
  }
}

usersRouter.get('/me', requireAuth, async (req: AuthenticatedRequest, res) => {
  const user = await getUserById(req.auth!.userId);
  if (!user) {
    res.status(404).json({ error: 'Kullanici bulunamadi.' });
    return;
  }
  res.status(200).json({ user });
});

usersRouter.post(
  '/me/voice-sample',
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const audioBase64 = String(req.body?.audioBase64 || '').trim();
    const mimeType = String(req.body?.mimeType || 'audio/m4a').trim();
    const sampleScript = String(req.body?.sampleScript || '').trim();

    if (!audioBase64) {
      res.status(400).json({ error: 'Ses ornegi gerekli.' });
      return;
    }
    if (!sampleScript) {
      res.status(400).json({ error: 'Okunan metin gerekli.' });
      return;
    }

    const extension = extensionForMimeType(mimeType);
    const userId = req.auth!.userId;
    const userDir = path.join(voiceSampleStorageDir, userId);
    const samplePath = path.join(userDir, `sample.${extension}`);
    await fs.mkdir(userDir, { recursive: true });
    await fs.writeFile(samplePath, Buffer.from(audioBase64, 'base64'));

    await setUserCustomVoiceSample({
      userId,
      samplePath,
      sampleScript,
    });

    const user = await getUserById(userId);
    res.status(200).json({ user });
  },
);

usersRouter.delete(
  '/me/voice-sample',
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const userId = req.auth!.userId;
    const user = await getUserById(userId);
    if (user?.custom_voice_sample_path) {
      await fs.rm(user.custom_voice_sample_path, { force: true });
    }

    await setUserCustomVoiceSample({
      userId,
      samplePath: null,
      sampleScript: null,
    });

    const nextUser = await getUserById(userId);
    res.status(200).json({ user: nextUser });
  },
);

usersRouter.get('/', requireAdmin, async (_req, res) => {
  const users = await listUsers();
  res.status(200).json({ users });
});

usersRouter.patch('/:userId/premium', requireAdmin, async (req: AuthenticatedRequest, res) => {
  const userId = String(req.params.userId || '');
  await setUserPremium(userId, Boolean(req.body?.isPremium));
  res.status(200).json({ ok: true });
});

usersRouter.patch('/:userId/role', requireOwner, async (req: AuthenticatedRequest, res) => {
  const userId = String(req.params.userId || '');
  const nextRole = String(req.body?.role || 'user');
  if (!['user', 'admin', 'owner'].includes(nextRole)) {
    res.status(400).json({ error: 'Gecersiz rol.' });
    return;
  }
  await setUserRole(userId, nextRole as 'user' | 'admin' | 'owner');
  res.status(200).json({ ok: true });
});
