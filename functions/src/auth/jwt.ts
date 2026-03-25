import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config';
import { UserRole } from '../db/types';

export interface SessionPayload {
  sub: string;
  email: string;
  role: UserRole;
}

export function signSessionToken(payload: SessionPayload): string {
  if (!JWT_SECRET) {
    throw new Error('Missing JWT_SECRET');
  }
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '30d' });
}

export function verifySessionToken(token: string): SessionPayload {
  if (!JWT_SECRET) {
    throw new Error('Missing JWT_SECRET');
  }
  return jwt.verify(token, JWT_SECRET) as SessionPayload;
}
