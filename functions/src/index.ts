import * as functions from 'firebase-functions';

import { createApp } from './app';
import { initializeFirebaseAdmin } from './firebaseAdmin';
import { generateStoryHandler } from './story/generateStory';

initializeFirebaseAdmin();

export const generateStory = functions.https.onRequest(createApp());
