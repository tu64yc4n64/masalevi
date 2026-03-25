import * as functions from 'firebase-functions';

import { createApp } from './app';
import { bootstrapDatabase } from './db/client';
import { initializeFirebaseAdmin } from './firebaseAdmin';

initializeFirebaseAdmin();

export const generateStory = functions.https.onRequest(async (req, res) => {
  await bootstrapDatabase();
  return createApp()(req, res);
});
