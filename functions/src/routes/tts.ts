import { Router } from 'express';

import { requireAuth } from '../auth/middleware';
import { getTtsProviderLabel, listTtsVoices } from '../tts/provider';

export const ttsRouter = Router();

ttsRouter.use(requireAuth);

ttsRouter.get('/voices', async (_req, res) => {
  try {
    const voices = await listTtsVoices();
    res.status(200).json({ voices });
  } catch (error: any) {
    const providerLabel = getTtsProviderLabel();
    res.status(500).json({
      error: error?.message || `${providerLabel} sesleri alinamadi.`,
    });
  }
});
