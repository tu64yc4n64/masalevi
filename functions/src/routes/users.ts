import { Router } from 'express';

import { requireAdmin, requireAuth, requireOwner, AuthenticatedRequest } from '../auth/middleware';
import { getUserById, listUsers, setUserPremium, setUserRole } from '../db/users';

export const usersRouter = Router();

usersRouter.get('/me', requireAuth, async (req: AuthenticatedRequest, res) => {
  const user = await getUserById(req.auth!.userId);
  if (!user) {
    res.status(404).json({ error: 'Kullanici bulunamadi.' });
    return;
  }
  res.status(200).json({ user });
});

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
