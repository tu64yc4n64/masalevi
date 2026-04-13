import { synthesizeSpeechWithCustomVoice } from './customVoice';
import {
  CUSTOM_USER_VOICE_ID,
  DEFAULT_SYSTEM_VOICE_ID,
} from './constants';
import { synthesizeSpeechWithPolly } from './polly';

export async function synthesizeSpeech(input: {
  text: string;
  selectedVoiceId: string;
  userId: string;
}): Promise<string | null> {
  if (input.selectedVoiceId === CUSTOM_USER_VOICE_ID) {
    try {
      return await synthesizeSpeechWithCustomVoice({
        userId: input.userId,
        text: input.text,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      if (
        message.includes('Kullanici ses ornegi bulunamadi.') ||
        message.includes('Kayitli ses ornegi dosyasi bulunamadi.')
      ) {
        return synthesizeSpeechWithPolly({
          text: input.text,
          selectedVoiceId: DEFAULT_SYSTEM_VOICE_ID,
        });
      }
      throw error;
    }
  }
  return synthesizeSpeechWithPolly(input);
}
