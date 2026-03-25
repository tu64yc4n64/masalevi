import * as adminSdk from 'firebase-admin';

export async function getUserRole(uid: string): Promise<'user' | 'admin' | 'owner'> {
  const doc = await adminSdk.firestore().collection('users').doc(uid).get();
  const roleRaw = doc.exists ? (doc.data()?.role as string | undefined) : undefined;
  if (roleRaw === 'owner') return 'owner';
  if (roleRaw === 'admin') return 'admin';
  return 'user';
}
