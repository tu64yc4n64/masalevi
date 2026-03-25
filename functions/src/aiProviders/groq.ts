import fetch from 'node-fetch';

import {
  GROQ_API_KEY,
  GROQ_MODEL,
} from '../config';

export async function generateStoryWithGroq(prompt: string): Promise<string> {
  if (!GROQ_API_KEY) {
    throw new Error('Missing GROQ_API_KEY');
  }

  // Groq OpenAI-compatible endpoint.
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${GROQ_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: GROQ_MODEL,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.8,
      max_tokens: 900,
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Groq error: ${res.status} ${text}`);
  }

  const data = (await res.json()) as any;
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== 'string' || !content.trim()) {
    throw new Error('Groq returned empty content');
  }
  return content.trim();
}

