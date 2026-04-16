import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { ServiceProviderModel } from '../../models/ServiceProvider.js';
import { UpsertServiceProviderProfileSchema } from './service_providers.schemas.js';

export function serviceProvidersRouter(env: Env) {
  const r = Router();

  r.get('/service-providers/me', requireAuth(env), requireRoles('serviceWorker', 'admin'), async (req, res) => {
    const doc = await ServiceProviderModel.findOne({ userId: req.auth!.sub });
    return res.json({
      provider: doc
        ? {
            userId: doc.userId.toString(),
            profession: doc.profession,
            nic: doc.nic ?? null,
            imageUrl: doc.imageUrl ?? null,
            planId: doc.planId ?? null,
            online: doc.online ?? false,
            location: doc.location ?? null,
            lastSeenAt: doc.lastSeenAt ?? null,
          }
        : null,
    });
  });

  r.put('/service-providers/me', requireAuth(env), requireRoles('serviceWorker', 'admin'), async (req, res, next) => {
    try {
      const body = UpsertServiceProviderProfileSchema.parse(req.body);
      await ServiceProviderModel.updateOne(
        { userId: req.auth!.sub },
        {
          $set: {
            profession: body.profession,
            nic: body.nic,
            imageUrl: body.imageUrl,
            planId: body.planId ?? 'monthly',
          },
        },
        { upsert: true },
      );
      const doc = await ServiceProviderModel.findOne({ userId: req.auth!.sub });
      return res.json({
        ok: true,
        provider: doc
          ? {
              userId: doc.userId.toString(),
              profession: doc.profession,
              nic: doc.nic ?? null,
              imageUrl: doc.imageUrl ?? null,
              planId: doc.planId ?? null,
            }
          : null,
      });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

