import { PORT } from './config';
import { createApp } from './app';
import { initializeFirebaseAdmin } from './firebaseAdmin';

initializeFirebaseAdmin();

const app = createApp();

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Masal Evi AI server listening on port ${PORT}`);
});
