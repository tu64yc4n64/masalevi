import { QueryResultRow } from 'pg';

import { query } from './client';

export interface DbStory {
  id: string;
  user_id: string;
  child_id: string;
  title: string;
  content: string;
  audio_url: string | null;
  audio_data_base64: string | null;
  is_favorite: boolean;
  created_at: Date;
}

interface StoryRow extends QueryResultRow {
  id: string;
  user_id: string;
  child_id: string;
  title: string;
  content: string;
  audio_url: string | null;
  audio_data_base64: string | null;
  is_favorite: boolean;
  created_at: Date;
}

export async function createStory(input: {
  userId: string;
  childId: string;
  title: string;
  content: string;
  audioUrl?: string | null;
  audioDataBase64?: string | null;
}): Promise<DbStory> {
  const result = await query<StoryRow>(
    `
      insert into stories (user_id, child_id, title, content, audio_url, audio_data_base64)
      values ($1, $2, $3, $4, $5, $6)
      returning id, user_id, child_id, title, content, audio_url, audio_data_base64, is_favorite, created_at
    `,
    [
      input.userId,
      input.childId,
      input.title,
      input.content,
      input.audioUrl ?? null,
      input.audioDataBase64 ?? null,
    ],
  );
  return mapStoryRow(result.rows[0]);
}

export async function listStories(userId: string): Promise<DbStory[]> {
  const result = await query<StoryRow>(
    `
      select id, user_id, child_id, title, content, audio_url, audio_data_base64, is_favorite, created_at
      from stories
      where user_id = $1
      order by created_at desc
    `,
    [userId],
  );
  return result.rows.map(mapStoryRow);
}

export async function setStoryFavorite(
  userId: string,
  storyId: string,
  nextValue: boolean,
): Promise<void> {
  await query(
    `update stories set is_favorite = $3 where id = $1 and user_id = $2`,
    [storyId, userId, nextValue],
  );
}

export async function deleteStory(
  userId: string,
  storyId: string,
): Promise<void> {
  await query(`delete from stories where id = $1 and user_id = $2`, [
    storyId,
    userId,
  ]);
}

export async function getStoryById(
  userId: string,
  storyId: string,
): Promise<DbStory | null> {
  const result = await query<StoryRow>(
    `
      select id, user_id, child_id, title, content, audio_url, audio_data_base64, is_favorite, created_at
      from stories
      where id = $1 and user_id = $2
      limit 1
    `,
    [storyId, userId],
  );
  const row = result.rows[0];
  return row ? mapStoryRow(row) : null;
}

function mapStoryRow(row: StoryRow): DbStory {
  return {
    id: row.id,
    user_id: row.user_id,
    child_id: row.child_id,
    title: row.title,
    content: row.content,
    audio_url: row.audio_url,
    audio_data_base64: row.audio_data_base64,
    is_favorite: row.is_favorite,
    created_at: new Date(row.created_at),
  };
}
