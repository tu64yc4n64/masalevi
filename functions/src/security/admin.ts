import { getUserById } from '../db/users';

export async function getUserRole(uid: string): Promise<'user' | 'admin' | 'owner'> {
  const user = await getUserById(uid);
  const roleRaw = user?.role;
  if (roleRaw === 'owner') return 'owner';
  if (roleRaw === 'admin') return 'admin';
  return 'user';
}
