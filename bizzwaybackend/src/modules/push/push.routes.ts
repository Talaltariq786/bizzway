import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { PushTokenModel } from '../../models/PushToken.js';
import { sendFcmToToken } from '../../utils/firebase_admin.js';
import { TestPushSchema, UpsertPushTokenSchema } from './push.schemas.js';

export function pushRouter(env: Env) {
  const r = Router();

  // Save/update my FCM/APNs token (called from app on login + onTokenRefresh)
  r.post('/push-tokens', requireAuth(env), async (req, res, next) => {
    try {
      const body = UpsertPushTokenSchema.parse(req.body);
      await PushTokenModel.updateOne(
        { userId: req.auth!.sub, token: body.token },
        {
          $set: {
            platform: body.platform,
            app: body.app,
            lastSeenAt: new Date(),
          },
        },
        { upsert: true },
      );
      return res.json({ ok: true });
    } catch (e) {
      return next(e);
    }
  });

  // Remove token (logout)
  r.delete('/push-tokens', requireAuth(env), async (req, res, next) => {
    try {
      const body = UpsertPushTokenSchema.pick({ token: true, platform: true, app: true }).parse(req.body);
      await PushTokenModel.deleteOne({ userId: req.auth!.sub, token: body.token });
      return res.json({ ok: true });
    } catch (e) {
      return next(e);
    }
  });

  // Test push (send to a token)
  r.post('/push/test', requireAuth(env), async (req, res, next) => {
    try {
      const body = TestPushSchema.parse(req.body);
      const id = await sendFcmToToken(env, body.token, { title: body.title, body: body.body });
      return res.status(201).json({ id });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

