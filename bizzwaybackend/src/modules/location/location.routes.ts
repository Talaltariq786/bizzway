import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { RiderModel } from '../../models/Rider.js';
import { ServiceProviderModel } from '../../models/ServiceProvider.js';
import { kmToMeters, parseNearParam } from '../../utils/geo.js';
import { UpdateLocationSchema } from './location.schemas.js';

export function locationRouter(env: Env) {
  const r = Router();

  r.post(
    '/riders/me/location',
    requireAuth(env),
    requireRoles('rider', 'admin'),
    async (req, res, next) => {
      try {
        const body = UpdateLocationSchema.parse(req.body);
        await RiderModel.updateOne(
          { userId: req.auth!.sub },
          {
            $set: {
              online: body.online ?? true,
              location: { type: 'Point', coordinates: [body.lng, body.lat] },
              lastSeenAt: new Date(),
            },
          },
          { upsert: true },
        );
        return res.json({ ok: true });
      } catch (e) {
        return next(e);
      }
    },
  );

  r.post(
    '/service-providers/me/location',
    requireAuth(env),
    requireRoles('serviceWorker', 'admin'),
    async (req, res, next) => {
      try {
        const body = UpdateLocationSchema.parse(req.body);
        await ServiceProviderModel.updateOne(
          { userId: req.auth!.sub },
          {
            $set: {
              online: body.online ?? true,
              location: { type: 'Point', coordinates: [body.lng, body.lat] },
              lastSeenAt: new Date(),
            },
            $setOnInsert: { profession: 'Service' },
          },
          { upsert: true },
        );
        return res.json({ ok: true });
      } catch (e) {
        return next(e);
      }
    },
  );

  r.get('/service-providers', async (req, res) => {
    const near = parseNearParam(typeof req.query.near === 'string' ? req.query.near : undefined);
    const radiusKm = Number(typeof req.query.radiusKm === 'string' ? req.query.radiusKm : '5');
    const profession = typeof req.query.profession === 'string' ? req.query.profession : undefined;

    const filter: any = { online: true };
    if (profession) filter.profession = profession;
    if (near) {
      filter.location = {
        $near: {
          $geometry: { type: 'Point', coordinates: [near.lng, near.lat] },
          $maxDistance: kmToMeters(Number.isFinite(radiusKm) ? radiusKm : 5),
        },
      };
    }

    const list = await ServiceProviderModel.find(filter)
      .populate('userId', 'name phone')
      .limit(50)
      .lean();

    const out = list.map((p: any) => {
      const u = p.userId;
      const name =
        typeof u === 'object' && u !== null && 'name' in u
          ? String(u.name ?? '').trim() || 'Service Provider'
          : 'Service Provider';
      const phone =
        typeof u === 'object' && u !== null && 'phone' in u
          ? String(u.phone ?? '').trim()
          : '';
      const coords = p.location?.coordinates as number[] | undefined;
      const lng = coords?.[0];
      const lat = coords?.[1];
      const sr = p.scrapRatesDisplay;
      let scrapRatesDisplay: Record<string, string> = {};
      if (sr instanceof Map) scrapRatesDisplay = Object.fromEntries(sr as Map<string, string>);
      else if (sr && typeof sr === 'object') scrapRatesDisplay = { ...sr };

      return {
        id: p._id.toString(),
        userId:
          typeof u === 'object' && u !== null && '_id' in u
            ? String(u._id)
            : String(p.userId),
        name,
        phone,
        profession: p.profession,
        online: !!p.online,
        lat,
        lng,
        location: p.location,
        scrapRatesDisplay,
        lastSeenAt: p.lastSeenAt ?? null,
      };
    });

    return res.json(out);
  });

  return r;
}

