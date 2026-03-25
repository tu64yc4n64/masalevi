import { Router } from 'express';

import { requireAuth } from '../auth/middleware';
import { listElevenLabsVoices } from '../tts/voices';

export const ttsRouter = Router();

ttsRouter.use(requireAuth);

ttsRouter.get('/voices', async (_req, res) => {
  try {
    const voices = await listElevenLabsVoices();
    res.status(200).json({ voices });
  } catch (error: any) {
    res.status(500).json({
      error: error?.message || 'ElevenLabs sesleri alinamadi.',
    });
  }
});
