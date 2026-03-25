export type UserRole = 'user' | 'admin' | 'owner';

export interface DbUser {
  id: string;
  email: string | null;
  role: UserRole;
  is_premium: boolean;
  story_count: number;
  story_reset_date: Date;
  trial_started_at: Date;
  trial_ends_at: Date;
}
