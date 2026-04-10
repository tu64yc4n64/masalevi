export const bootstrapSql = `
create extension if not exists "pgcrypto";

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  password_hash text,
  google_sub text unique,
  display_name text,
  role text not null default 'user',
  is_premium boolean not null default false,
  story_count integer not null default 0,
  story_reset_date timestamptz not null default now(),
  trial_started_at timestamptz not null default now(),
  trial_ends_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  name text not null,
  age integer not null,
  gender text not null,
  interests jsonb not null default '[]'::jsonb,
  emoji_avatar text not null default '🙂',
  preferred_theme text,
  preferred_value text,
  selected_voice_id text not null default 'Burcu',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists children_user_id_idx on children(user_id);

create table if not exists stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  child_id uuid not null references children(id) on delete cascade,
  title text not null,
  content text not null,
  selected_voice_id text,
  audio_url text,
  audio_data_base64 text,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists stories_user_id_idx on stories(user_id);
create index if not exists stories_child_id_idx on stories(child_id);

alter table stories add column if not exists audio_url text;
alter table stories add column if not exists audio_data_base64 text;
alter table stories add column if not exists selected_voice_id text;
`;
