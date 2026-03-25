import { Request, Response, NextFunction } from 'express';

import { verifySessionToken } from './jwt';
import { UserRole } from '../db/types';

export interface AuthenticatedRequest extends Request {
  auth?: {
    userId: string;
    email: string;
    role: UserRole;
  };
}

function getBearerToken(req: Request): string | null {
  const header = req.get('Authorization') || req.headers.authorization;
  if (!header || typeof header !== 'string') return null;
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return null;
  return token;
}

export function requireAuth(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): void {
  try {
    const token = getBearerToken(req);
    if (!token) {
      res.status(401).json({ error: 'Missing Authorization Bearer token' });
      return;
    }
    const payload = verifySessionToken(token);
    req.auth = {
      userId: payload.sub,
      email: payload.email,
      role: payload.role,
    };
    next();
  } catch (error: any) {
    res.status(401).json({ error: error?.message || 'Unauthorized' });
  }
}

export function requireAdmin(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): void {
  requireAuth(req, res, () => {
    const role = req.auth?.role;
    if (role !== 'admin' && role !== 'owner') {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }
    next();
  });
}

export function requireOwner(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): void {
  requireAuth(req, res, () => {
    if (req.auth?.role !== 'owner') {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }
    next();
  });
}
