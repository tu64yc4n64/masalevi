import * as adminSdk from 'firebase-admin';

let initialized = false;

export function initializeFirebaseAdmin(): void {
  if (initialized || adminSdk.apps.length > 0) {
    initialized = true;
    return;
  }

  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '';
  if (rawServiceAccount) {
    const serviceAccount = JSON.parse(rawServiceAccount);
    adminSdk.initializeApp({
      credential: adminSdk.credential.cert(serviceAccount),
    });
    initialized = true;
    return;
  }

  adminSdk.initializeApp();
  initialized = true;
}
