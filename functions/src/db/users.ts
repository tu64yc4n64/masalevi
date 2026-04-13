import { QueryResultRow } from 'pg';

import { query } from './client';
import { DbUser, UserRole } from './types';
import { CUSTOM_USER_VOICE_ID } from '../tts/constants';

interface UserRow extends QueryResultRow, DbUser {
  password_hash: string | null;
  google_sub: string | null;
  display_name: string | null;
}

export interface CreateUserInput {
  email: string;
  passwordHash?: string;
  googleSub?: string;
  displayName?: string;
}

export async function createUser(input: CreateUserInput): Promise<DbUser> {
  const result = await query<UserRow>(
    `
      insert into users (email, password_hash, google_sub, display_name, story_reset_date)
      values ($1, $2, $3, $4, date_trunc('month', now()) + interval '1 month')
      returning id, email, role, is_premium, story_count, story_reset_date, trial_started_at, trial_ends_at,
                custom_voice_sample_path, custom_voice_sample_script, custom_voice_updated_at,
                password_hash, google_sub, display_name
    `,
    [
      input.email.toLowerCase(),
      input.passwordHash ?? null,
      input.googleSub ?? null,
      input.displayName ?? null,
    ],
  );
  return mapUserRow(result.rows[0]);
}

export async function findUserByEmail(email: string): Promise<(DbUser & { passwordHash: string | null; googleSub: string | null; displayName: string | null }) | null> {
  const result = await query<UserRow>(
    `
      select id, email, role, is_premium, story_count, story_reset_date, trial_started_at, trial_ends_at,
             custom_voice_sample_path, custom_voice_sample_script, custom_voice_updated_at,
             password_hash, google_sub, display_name
      from users
      where email = $1
      limit 1
    `,
    [email.toLowerCase()],
  );
  const row = result.rows[0];
  if (!row) return null;
  return {
    ...mapUserRow(row),
    passwordHash: row.password_hash,
    googleSub: row.google_sub,
    displayName: row.display_name,
  };
}

export async function findUserByGoogleSub(sub: string): Promise<DbUser | null> {
  const result = await query<UserRow>(
    `
      select id, email, role, is_premium, story_count, story_reset_date, trial_started_at, trial_ends_at,
             custom_voice_sample_path, custom_voice_sample_script, custom_voice_updated_at,
             password_hash, google_sub, display_name
      from users
      where google_sub = $1
      limit 1
    `,
    [sub],
  );
  const row = result.rows[0];
  return row ? mapUserRow(row) : null;
}

export async function linkGoogleIdentity(
  userId: string,
  googleSub: string,
  displayName: string,
): Promise<void> {
  await query(
    `
      update users
      set google_sub = $2, display_name = coalesce($3, display_name), updated_at = now()
      where id = $1
    `,
    [userId, googleSub, displayName],
  );
}

export async function getUserById(userId: string): Promise<DbUser | null> {
  const result = await query<UserRow>(
    `
      select id, email, role, is_premium, story_count, story_reset_date, trial_started_at, trial_ends_at,
             custom_voice_sample_path, custom_voice_sample_script, custom_voice_updated_at,
             password_hash, google_sub, display_name
      from users
      where id = $1
      limit 1
    `,
    [userId],
  );
  const row = result.rows[0];
  return row ? mapUserRow(row) : null;
}

export async function listUsers(): Promise<DbUser[]> {
  const result = await query<UserRow>(
    `
      select id, email, role, is_premium, story_count, story_reset_date, trial_started_at, trial_ends_at,
             custom_voice_sample_path, custom_voice_sample_script, custom_voice_updated_at,
             password_hash, google_sub, display_name
      from users
      order by email asc nulls last, created_at asc
    `,
  );
  return result.rows.map(mapUserRow);
}

export async function setUserRole(userId: string, role: UserRole): Promise<void> {
  await query(`update users set role = $2, updated_at = now() where id = $1`, [
    userId,
    role,
  ]);
}

export async function setUserPremium(
  userId: string,
  isPremium: boolean,
): Promise<void> {
  await query(
    `update users set is_premium = $2, updated_at = now() where id = $1`,
    [userId, isPremium],
  );
}

export async function incrementStoryCount(userId: string): Promise<void> {
  await query(
    `
      update users
      set
        story_count = case
          when now() > story_reset_date then 1
          else story_count + 1
        end,
        story_reset_date = case
          when now() > story_reset_date then date_trunc('month', now()) + interval '1 month'
          else story_reset_date
        end,
        updated_at = now()
      where id = $1
    `,
    [userId],
  );
}

export async function setUserCustomVoiceSample(input: {
  userId: string;
  samplePath: string | null;
  sampleScript: string | null;
}): Promise<void> {
  await query(
    `
      update users
      set
        custom_voice_sample_path = $2::text,
        custom_voice_sample_script = $3::text,
        custom_voice_updated_at = case when $2::text is null then null else now() end,
        updated_at = now()
      where id = $1
    `,
    [input.userId, input.samplePath, input.sampleScript],
  );
  await query(
    `
      delete from story_audio_cache
      using stories
      where story_audio_cache.story_id = stories.id
        and stories.user_id = $1
        and story_audio_cache.voice_id = $2
    `,
    [input.userId, CUSTOM_USER_VOICE_ID],
  );
}

function mapUserRow(row: UserRow): DbUser {
  return {
    id: row.id,
    email: row.email,
    role: row.role,
    is_premium: row.is_premium,
    story_count: row.story_count,
    story_reset_date: new Date(row.story_reset_date),
    trial_started_at: new Date(row.trial_started_at),
    trial_ends_at: new Date(row.trial_ends_at),
    custom_voice_sample_path: row.custom_voice_sample_path,
    custom_voice_sample_script: row.custom_voice_sample_script,
    custom_voice_updated_at: row.custom_voice_updated_at
      ? new Date(row.custom_voice_updated_at)
      : null,
  };
}
