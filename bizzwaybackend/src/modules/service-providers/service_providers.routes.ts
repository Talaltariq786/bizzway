import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { ServiceProviderModel } from '../../models/ServiceProvider.js';
import { UpsertServiceProviderProfileSchema } from './service_providers.schemas.js';

function scrapRatesToJson(doc: { scrapRatesDisplay?: unknown } | null): Record<string, string> {
  const m = doc?.scrapRatesDisplay as unknown;
  if (!m) return {};
  if (m instanceof Map) return Object.fromEntries(m as Map<string, string>);
  if (typeof m === 'object') return { ...(m as Record<string, string>) };
  return {};
}

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
            scrapRatesDisplay: scrapRatesToJson(doc),
          }
        : null,
    });
  });

  r.put('/service-providers/me', requireAuth(env), requireRoles('serviceWorker', 'admin'), async (req, res, next) => {
    try {
      const body = UpsertServiceProviderProfileSchema.parse(req.body);
      const $set: Record<string, unknown> = {
        profession: body.profession,
        planId: body.planId ?? 'monthly',
      };
      if (body.nic !== undefined) $set.nic = body.nic;
      if (body.imageUrl !== undefined) $set.imageUrl = body.imageUrl;
      if (body.scrapRatesDisplay !== undefined) {
        $set.scrapRatesDisplay =
          body.scrapRatesDisplay && Object.keys(body.scrapRatesDisplay).length > 0
            ? new Map(Object.entries(body.scrapRatesDisplay))
            : new Map();
      }
      await ServiceProviderModel.updateOne({ userId: req.auth!.sub }, { $set }, { upsert: true });
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
              online: doc.online ?? false,
              scrapRatesDisplay: scrapRatesToJson(doc),
            }
          : null,
      });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

