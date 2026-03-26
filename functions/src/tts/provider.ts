import { TTS_PROVIDER } from '../config';
import { synthesizeSpeechWithElevenLabs } from './elevenlabs';
import { synthesizeSpeechWithPolly, listPollyVoices } from './polly';
import { listElevenLabsVoices } from './voices';

export function getTtsProviderLabel(): string {
  return TTS_PROVIDER === 'polly' ? 'Amazon Polly' : 'ElevenLabs';
}

export async function listTtsVoices() {
  if (TTS_PROVIDER === 'polly') {
    return listPollyVoices();
  }
  return listElevenLabsVoices();
}

export async function synthesizeSpeech(input: {
  text: string;
  selectedVoiceId: string;
}): Promise<string | null> {
  if (TTS_PROVIDER === 'polly') {
    return synthesizeSpeechWithPolly(input);
  }
  return synthesizeSpeechWithElevenLabs(input);
}
