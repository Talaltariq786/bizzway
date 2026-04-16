import { Router } from 'express';
import crypto from 'crypto';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { CreateUploadSchema } from './uploads.schemas.js';

// MVP: no binary upload. This endpoint only returns an upload "placeholder"
// so mobile/web clients can integrate real storage later (S3/Cloudinary/etc).
export function uploadsRouter(env: Env) {
  const r = Router();

  r.post('/uploads', requireAuth(env), async (req, res, next) => {
    try {
      const body = CreateUploadSchema.parse(req.body);
      const id = crypto.randomUUID();
      const safeName = (body.filename ?? 'file').replaceAll(/[^a-zA-Z0-9._-]/g, '_');

      // Placeholder URL (no storage yet). Replace with real CDN or signed URL flow later.
      const url = `https://uploads.bizzway.local/${body.purpose}/${id}/${safeName}`;

      return res.status(201).json({
        id,
        purpose: body.purpose,
        url,
        note: 'Stub upload endpoint (no binary stored).',
      });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

