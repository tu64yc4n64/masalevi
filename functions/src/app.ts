import cors from 'cors';
import express from 'express';

import { generateStoryHandler } from './story/generateStory';

export function createApp(): express.Express {
  const app = express();

  app.use(cors({ origin: true }));
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_req, res) => {
    res.status(200).json({ ok: true });
  });

  // Cloud Functions root path.
  app.post('/', generateStoryHandler);
  // Standalone server path.
  app.post('/generateStory', generateStoryHandler);

  return app;
}
