import fetch from 'node-fetch';

import { ELEVENLABS_API_KEY, ELEVENLABS_MODEL } from '../config';

const defaultVoiceMap: Record<string, string> = {
  sevgi_teyze: 'EXAVITQu4vr4xnSDxMaL',
  peri_ana: '21m00Tcm4TlvDq8ikWAM',
  dede: 'ErXwobaYiN019PkySvjV',
  kahraman: 'TxGEqnHWrfWFTfGW9XjX',
};

export async function synthesizeSpeechWithElevenLabs(input: {
  text: string;
  selectedVoiceId: string;
}): Promise<string | null> {
  if (!ELEVENLABS_API_KEY) {
    return null;
  }

  const voiceId =
    defaultVoiceMap[input.selectedVoiceId] ?? defaultVoiceMap.sevgi_teyze;

  const response = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
    {
      method: 'POST',
      headers: {
        'xi-api-key': ELEVENLABS_API_KEY,
        Accept: 'audio/mpeg',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text: input.text,
        model_id: ELEVENLABS_MODEL,
        output_format: 'mp3_44100_128',
        voice_settings: {
          stability: 0.45,
          similarity_boost: 0.8,
          style: 0.15,
          use_speaker_boost: true,
          speed: 0.95,
        },
      }),
    },
  );

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`ElevenLabs error: ${response.status} ${body}`);
  }

  const buffer = Buffer.from(await response.arrayBuffer());
  return buffer.toString('base64');
}
