import { Router } from 'express';

import { verifyGoogleIdToken } from '../auth/google';
import { signSessionToken } from '../auth/jwt';
import { hashPassword, verifyPassword } from '../auth/password';
import {
  createUser,
  findUserByEmail,
  findUserByGoogleSub,
  getUserById,
  linkGoogleIdentity,
} from '../db/users';
import { requireAuth, AuthenticatedRequest } from '../auth/middleware';

export const authRouter = Router();

authRouter.post('/register', async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    if (!email || !email.includes('@')) {
      res.status(400).json({ error: 'Gecerli bir e-posta gerekli.' });
      return;
    }
    if (password.length < 6) {
      res.status(400).json({ error: 'Sifre en az 6 karakter olmali.' });
      return;
    }
    const existing = await findUserByEmail(email);
    if (existing != null) {
      res.status(409).json({ error: 'Bu e-posta ile zaten bir hesap var.' });
      return;
    }
    const passwordHash = await hashPassword(password);
    const user = await createUser({ email, passwordHash, displayName: email });
    const token = signSessionToken({
      sub: user.id,
      email: user.email || '',
      role: user.role,
    });
    res.status(200).json({ token, user });
  } catch (error: any) {
    res.status(500).json({ error: error?.message || 'Kayit basarisiz.' });
  }
});

authRouter.post('/login', async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    const user = await findUserByEmail(email);
    if (!user?.passwordHash) {
      res.status(401).json({ error: 'Bu e-posta ile kayitli hesap bulunamadi.' });
      return;
    }
    const valid = await verifyPassword(password, user.passwordHash);
    if (!valid) {
      res.status(401).json({ error: 'Sifre hatali.' });
      return;
    }
    const token = signSessionToken({
      sub: user.id,
      email: user.email || '',
      role: user.role,
    });
    res.status(200).json({ token, user });
  } catch (error: any) {
    res.status(500).json({ error: error?.message || 'Giris basarisiz.' });
  }
});

authRouter.post('/google', async (req, res) => {
  try {
    const idToken = String(req.body?.idToken || '');
    if (!idToken) {
      res.status(400).json({ error: 'Google token gerekli.' });
      return;
    }
    const googleUser = await verifyGoogleIdToken(idToken);
    let user = await findUserByGoogleSub(googleUser.sub);
    if (!user) {
      const existing = await findUserByEmail(googleUser.email);
      if (existing) {
        await linkGoogleIdentity(existing.id, googleUser.sub, googleUser.name);
        user = await getUserById(existing.id);
      } else {
        user = await createUser({
          email: googleUser.email,
          googleSub: googleUser.sub,
          displayName: googleUser.name,
        });
      }
    }
    if (!user) {
      throw new Error('Google kullanicisi olusturulamadi.');
    }
    const token = signSessionToken({
      sub: user.id,
      email: user.email || '',
      role: user.role,
    });
    res.status(200).json({ token, user });
  } catch (error: any) {
    res.status(500).json({ error: error?.message || 'Google girisi basarisiz.' });
  }
});

authRouter.get('/me', requireAuth, async (req: AuthenticatedRequest, res) => {
  const user = await getUserById(req.auth!.userId);
  if (!user) {
    res.status(404).json({ error: 'Kullanici bulunamadi.' });
    return;
  }
  res.status(200).json({ user });
});
