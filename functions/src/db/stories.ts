import { QueryResultRow } from 'pg';

import { query } from './client';

export interface DbStory {
  id: string;
  user_id: string;
  child_id: string;
  title: string;
  content: string;
  audio_url: string | null;
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
  is_favorite: boolean;
  created_at: Date;
}

export async function createStory(input: {
  userId: string;
  childId: string;
  title: string;
  content: string;
}): Promise<DbStory> {
  const result = await query<StoryRow>(
    `
      insert into stories (user_id, child_id, title, content)
      values ($1, $2, $3, $4)
      returning id, user_id, child_id, title, content, audio_url, is_favorite, created_at
    `,
    [input.userId, input.childId, input.title, input.content],
  );
  return mapStoryRow(result.rows[0]);
}

export async function listStories(userId: string): Promise<DbStory[]> {
  const result = await query<StoryRow>(
    `
      select id, user_id, child_id, title, content, audio_url, is_favorite, created_at
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

function mapStoryRow(row: StoryRow): DbStory {
  return {
    id: row.id,
    user_id: row.user_id,
    child_id: row.child_id,
    title: row.title,
    content: row.content,
    audio_url: row.audio_url,
    is_favorite: row.is_favorite,
    created_at: new Date(row.created_at),
  };
}
