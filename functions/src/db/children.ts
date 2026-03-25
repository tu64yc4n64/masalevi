import { QueryResultRow } from 'pg';

import { query } from './client';

export interface DbChild {
  id: string;
  user_id: string;
  name: string;
  age: number;
  gender: string;
  interests: string[];
  emoji_avatar: string;
  preferred_theme: string | null;
  preferred_value: string | null;
  selected_voice_id: string;
}

interface ChildRow extends QueryResultRow {
  id: string;
  user_id: string;
  name: string;
  age: number;
  gender: string;
  interests: string[];
  emoji_avatar: string;
  preferred_theme: string | null;
  preferred_value: string | null;
  selected_voice_id: string;
}

export async function listChildren(userId: string): Promise<DbChild[]> {
  const result = await query<ChildRow>(
    `
      select id, user_id, name, age, gender, interests, emoji_avatar, preferred_theme, preferred_value, selected_voice_id
      from children
      where user_id = $1
      order by created_at asc
    `,
    [userId],
  );
  return result.rows.map(mapChildRow);
}

export async function getChild(
  userId: string,
  childId: string,
): Promise<DbChild | null> {
  const result = await query<ChildRow>(
    `
      select id, user_id, name, age, gender, interests, emoji_avatar, preferred_theme, preferred_value, selected_voice_id
      from children
      where user_id = $1 and id = $2
      limit 1
    `,
    [userId, childId],
  );
  const row = result.rows[0];
  return row ? mapChildRow(row) : null;
}

export async function upsertChild(
  userId: string,
  child: Omit<DbChild, 'user_id'>,
): Promise<DbChild> {
  const result = await query<ChildRow>(
    `
      insert into children (
        id, user_id, name, age, gender, interests, emoji_avatar, preferred_theme, preferred_value, selected_voice_id
      )
      values ($1, $2, $3, $4, $5, $6::jsonb, $7, $8, $9, $10)
      on conflict (id)
      do update set
        name = excluded.name,
        age = excluded.age,
        gender = excluded.gender,
        interests = excluded.interests,
        emoji_avatar = excluded.emoji_avatar,
        preferred_theme = excluded.preferred_theme,
        preferred_value = excluded.preferred_value,
        selected_voice_id = excluded.selected_voice_id,
        updated_at = now()
      returning id, user_id, name, age, gender, interests, emoji_avatar, preferred_theme, preferred_value, selected_voice_id
    `,
    [
      child.id,
      userId,
      child.name,
      child.age,
      child.gender,
      JSON.stringify(child.interests),
      child.emoji_avatar,
      child.preferred_theme,
      child.preferred_value,
      child.selected_voice_id,
    ],
  );
  return mapChildRow(result.rows[0]);
}

function mapChildRow(row: ChildRow): DbChild {
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    age: row.age,
    gender: row.gender,
    interests: Array.isArray(row.interests) ? row.interests : [],
    emoji_avatar: row.emoji_avatar,
    preferred_theme: row.preferred_theme,
    preferred_value: row.preferred_value,
    selected_voice_id: row.selected_voice_id,
  };
}
