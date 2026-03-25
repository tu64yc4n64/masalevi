import fetch from 'node-fetch';

import {
  CLAUDE_API_KEY,
  CLAUDE_MODEL,
} from '../config';

export async function generateStoryWithClaude(prompt: string): Promise<string> {
  if (!CLAUDE_API_KEY) {
    throw new Error('Missing CLAUDE_API_KEY');
  }

  // Anthropics Messages API (skeleton).
  // Reference: https://docs.anthropic.com/en/docs
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': CLAUDE_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 900,
      temperature: 0.8,
      system: 'Sen bir Türk çocuk masalı asistanısın.',
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Claude error: ${res.status} ${text}`);
  }

  const data = (await res.json()) as any;
  // Expect response.content as array.
  const blocks = data?.content;
  const content = Array.isArray(blocks)
    ? blocks.map((b: any) => b?.text).filter(Boolean).join('')
    : data?.content?.[0]?.text;

  if (typeof content !== 'string' || !content.trim()) {
    throw new Error('Claude returned empty content');
  }
  return content.trim();
}

