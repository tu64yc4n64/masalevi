import { OAuth2Client } from 'google-auth-library';

const client = new OAuth2Client();

export interface GoogleIdentity {
  sub: string;
  email: string;
  name: string;
}

export async function verifyGoogleIdToken(
  idToken: string,
): Promise<GoogleIdentity> {
  const ticket = await client.verifyIdToken({ idToken });
  const payload = ticket.getPayload();
  if (!payload?.sub || !payload.email) {
    throw new Error('Invalid Google token');
  }
  return {
    sub: payload.sub,
    email: payload.email,
    name: payload.name || payload.email,
  };
}
