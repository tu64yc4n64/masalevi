import { PORT } from './config';
import { createApp } from './app';
import { bootstrapDatabase } from './db/client';
import { initializeFirebaseAdmin } from './firebaseAdmin';

initializeFirebaseAdmin();

async function start(): Promise<void> {
  await bootstrapDatabase();
  const app = createApp();
  app.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`Masal Evi AI server listening on port ${PORT}`);
  });
}

void start();
