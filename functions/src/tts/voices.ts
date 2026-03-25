import fetch from 'node-fetch';

import { ELEVENLABS_API_KEY } from '../config';

export interface ElevenLabsVoice {
  voice_id: string;
  name: string;
  preview_url: string | null;
  labels?: Record<string, string>;
  category?: string;
}

export async function listElevenLabsVoices(): Promise<ElevenLabsVoice[]> {
  if (!ELEVENLABS_API_KEY) {
    throw new Error('Missing ELEVENLABS_API_KEY');
  }

  const response = await fetch('https://api.elevenlabs.io/v2/voices?limit=100', {
    headers: {
      'xi-api-key': ELEVENLABS_API_KEY,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`ElevenLabs voices error: ${response.status} ${body}`);
  }

  const data = (await response.json()) as {
    voices?: Array<{
      voice_id?: string;
      name?: string;
      preview_url?: string | null;
      labels?: Record<string, string>;
      category?: string;
    }>;
  };

  return (data.voices ?? [])
    .filter((voice) => voice.voice_id && voice.name)
    .map((voice) => ({
      voice_id: voice.voice_id!,
      name: voice.name!,
      preview_url: voice.preview_url ?? null,
      labels: voice.labels ?? {},
      category: voice.category,
    }))
    .sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
}
