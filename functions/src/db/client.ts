import { Pool, QueryResult, QueryResultRow } from 'pg';

import { bootstrapSql } from './schema';

let pool: Pool | null = null;

function getDatabaseUrl(): string {
  const value = process.env.DATABASE_URL || '';
  if (!value) {
    throw new Error('Missing DATABASE_URL');
  }
  return value;
}

export function getPool(): Pool {
  if (pool != null) return pool;

  const connectionString = getDatabaseUrl();
  pool = new Pool({
    connectionString,
    ssl: connectionString.includes('localhost')
        ? false
        : { rejectUnauthorized: false },
  });
  return pool;
}

export async function query<T extends QueryResultRow = QueryResultRow>(
  text: string,
  params: unknown[] = [],
): Promise<QueryResult<T>> {
  return getPool().query<T>(text, params);
}

export async function bootstrapDatabase(): Promise<void> {
  await query(bootstrapSql);
}
