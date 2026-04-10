import {
  DescribeVoicesCommand,
  Engine,
  PollyClient,
  SynthesizeSpeechCommand,
  VoiceId,
} from '@aws-sdk/client-polly';

import {
  AWS_ACCESS_KEY_ID,
  AWS_REGION,
  AWS_SECRET_ACCESS_KEY,
  POLLY_ENGINE,
} from '../config';

interface TtsVoiceResponse {
  voice_id: string;
  name: string;
  preview_url: string | null;
  labels?: Record<string, string>;
  category?: string;
}

const legacyVoiceMap: Record<string, string> = {
  sevgi_teyze: 'Burcu',
  peri_ana: 'Burcu',
  dede: 'Filiz',
  kahraman: 'Burcu',
};

let pollyClient: PollyClient | null = null;

function getPollyClient(): PollyClient {
  if (!AWS_ACCESS_KEY_ID || !AWS_SECRET_ACCESS_KEY) {
    throw new Error('Missing AWS Polly credentials');
  }
  if (pollyClient) return pollyClient;
  pollyClient = new PollyClient({
    region: AWS_REGION,
    credentials: {
      accessKeyId: AWS_ACCESS_KEY_ID,
      secretAccessKey: AWS_SECRET_ACCESS_KEY,
    },
  });
  return pollyClient;
}

function resolveVoiceId(selectedVoiceId: string): VoiceId {
  const trimmed = selectedVoiceId.trim();
  const resolved = !trimmed ? 'Burcu' : legacyVoiceMap[trimmed] ?? trimmed;
  return resolved as VoiceId;
}

function resolveEngine(voiceId: string): Engine {
  if (voiceId === 'Filiz') return 'standard';
  if (voiceId === 'Burcu') return 'neural';
  return POLLY_ENGINE === 'standard' ? 'standard' : 'neural';
}

export async function listPollyVoices(): Promise<TtsVoiceResponse[]> {
  const client = getPollyClient();
  const [standardResponse, neuralResponse] = await Promise.all([
    client.send(
      new DescribeVoicesCommand({
        LanguageCode: 'tr-TR',
        Engine: 'standard',
        IncludeAdditionalLanguageCodes: false,
      }),
    ),
    client.send(
      new DescribeVoicesCommand({
        LanguageCode: 'tr-TR',
        Engine: 'neural',
        IncludeAdditionalLanguageCodes: false,
      }),
    ),
  ]);

  const voicesById = new Map<string, TtsVoiceResponse>();
  for (const voice of [
    ...(standardResponse.Voices ?? []),
    ...(neuralResponse.Voices ?? []),
  ]) {
    if (voice.Id == null || voice.Name == null) continue;
    voicesById.set(voice.Id!, {
      voice_id: voice.Id!,
      name: voice.Name!,
      preview_url: null,
      labels: {
        language: voice.LanguageCode ?? 'tr-TR',
      },
      category: `Amazon Polly ${voice.Gender ?? ''}`.trim(),
    });
  }

  const voices = Array.from(voicesById.values());
  voices.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
  return voices;
}

export async function synthesizeSpeechWithPolly(input: {
  text: string;
  selectedVoiceId: string;
}): Promise<string | null> {
  const client = getPollyClient();
  const voiceId = resolveVoiceId(input.selectedVoiceId);
  const response = await client.send(
    new SynthesizeSpeechCommand({
      Engine: resolveEngine(voiceId),
      OutputFormat: 'mp3',
      Text: input.text,
      VoiceId: voiceId,
      LanguageCode: 'tr-TR',
    }),
  );

  if (!response.AudioStream) {
    throw new Error('Amazon Polly ses verisi donmedi.');
  }

  const bytes = await response.AudioStream.transformToByteArray();
  return Buffer.from(bytes).toString('base64');
}
