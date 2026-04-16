import fs from 'fs';

import admin from 'firebase-admin';

import type { Env } from '../config/env.js';

let _app: admin.app.App | null = null;

function _loadServiceAccount(env: Env): admin.ServiceAccount | null {
  if (env.FIREBASE_SERVICE_ACCOUNT_JSON && env.FIREBASE_SERVICE_ACCOUNT_JSON.trim().length > 0) {
    return JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as admin.ServiceAccount;
  }
  if (env.FIREBASE_SERVICE_ACCOUNT_PATH && env.FIREBASE_SERVICE_ACCOUNT_PATH.trim().length > 0) {
    const raw = fs.readFileSync(env.FIREBASE_SERVICE_ACCOUNT_PATH, 'utf8');
    return JSON.parse(raw) as admin.ServiceAccount;
  }
  return null;
}

export function firebaseAdminApp(env: Env): admin.app.App {
  if (_app) return _app;
  const svc = _loadServiceAccount(env);
  if (!svc) {
    throw new Error(
      'Firebase Admin not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH.',
    );
  }
  _app = admin.initializeApp({
    credential: admin.credential.cert(svc),
    projectId: env.FIREBASE_PROJECT_ID,
  });
  return _app;
}

export async function sendFcmToToken(
  env: Env,
  token: string,
  msg: { title: string; body: string; data?: Record<string, string> },
) {
  firebaseAdminApp(env);
  return await admin.messaging().send({
    token,
    notification: {
      title: msg.title,
      body: msg.body,
    },
    data: msg.data,
  });
}

