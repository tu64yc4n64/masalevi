import { TTS_PROVIDER } from '../config';
import {
  synthesizeSpeechWithCustomVoice,
} from './customVoice';
import { CUSTOM_USER_VOICE_ID } from './constants';
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
  userId: string;
}): Promise<string | null> {
  if (input.selectedVoiceId === CUSTOM_USER_VOICE_ID) {
    return synthesizeSpeechWithCustomVoice({
      userId: input.userId,
      text: input.text,
    });
  }
  if (TTS_PROVIDER === 'polly') {
    return synthesizeSpeechWithPolly(input);
  }
  return synthesizeSpeechWithElevenLabs(input);
}
