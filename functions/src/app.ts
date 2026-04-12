import cors from 'cors';
import express from 'express';

import { requireAuth } from './auth/middleware';
import { authRouter } from './routes/auth';
import { childrenRouter } from './routes/children';
import { storiesRouter } from './routes/stories';
import { ttsRouter } from './routes/tts';
import { usersRouter } from './routes/users';
import { generateStoryHandler } from './story/generateStory';

export function createApp(): express.Express {
  const app = express();

  app.use(cors({ origin: true }));
  app.use(express.json({ limit: '12mb' }));

  app.get('/health', (_req, res) => {
    res.status(200).json({ ok: true });
  });

  app.use('/auth', authRouter);
  app.use('/children', childrenRouter);
  app.use('/stories', storiesRouter);
  app.use('/tts', ttsRouter);
  app.use('/users', usersRouter);

  // Cloud Functions root path.
  app.post('/', requireAuth, generateStoryHandler);
  // Standalone server path.
  app.post('/generateStory', requireAuth, generateStoryHandler);

  return app;
}
