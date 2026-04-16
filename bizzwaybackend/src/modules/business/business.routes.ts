import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { BusinessModel } from '../../models/Business.js';
import { ProductModel } from '../../models/Product.js';
import { kmToMeters, parseNearParam } from '../../utils/geo.js';
import { CreateBusinessSchema, CreateProductSchema, PatchProductSchema } from './business.schemas.js';

export function businessRouter(env: Env) {
  const r = Router();

  r.post(
    '/',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res, next) => {
      try {
        const body = CreateBusinessSchema.parse(req.body);
        const b = await BusinessModel.create({
          ownerId: req.auth!.sub,
          name: body.name,
          type: body.type,
          address: body.address,
          location: { type: 'Point', coordinates: [body.lng, body.lat] },
        });
        return res.status(201).json({ id: b._id.toString() });
      } catch (e) {
        return next(e);
      }
    },
  );

  r.get('/', async (req, res) => {
    const near = parseNearParam(typeof req.query.near === 'string' ? req.query.near : undefined);
    const radiusKm = Number(typeof req.query.radiusKm === 'string' ? req.query.radiusKm : '5');
    const type = typeof req.query.type === 'string' ? req.query.type : undefined;

    const filter: any = {};
    if (type) filter.type = type;

    if (near) {
      filter.location = {
        $near: {
          $geometry: { type: 'Point', coordinates: [near.lng, near.lat] },
          $maxDistance: kmToMeters(Number.isFinite(radiusKm) ? radiusKm : 5),
        },
      };
    }

    const list = await BusinessModel.find(filter).limit(50).sort({ createdAt: -1 });
    return res.json(
      list.map((b) => ({
        id: b._id.toString(),
        name: b.name,
        type: b.type,
        address: b.address,
        location: b.location,
      })),
    );
  });

  /** Logged-in owner’s businesses (must be before /:id — otherwise "mine" is parsed as ObjectId). */
  r.get(
    '/mine',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res) => {
      const list = await BusinessModel.find({ ownerId: req.auth!.sub })
        .sort({ createdAt: -1 })
        .limit(30);
      return res.json({
        businesses: list.map((b) => ({
          id: b._id.toString(),
          name: b.name,
          type: b.type,
          address: b.address,
          location: b.location,
        })),
      });
    },
  );

  r.get('/:id', async (req, res) => {
    const b = await BusinessModel.findById(req.params.id);
    if (!b) return res.status(404).json({ error: 'not_found' });
    return res.json({
      id: b._id.toString(),
      name: b.name,
      type: b.type,
      address: b.address,
      location: b.location,
      ownerId: b.ownerId?.toString?.() ?? b.ownerId,
    });
  });

  r.post(
    '/:id/products',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res, next) => {
      try {
        const businessId = req.params.id;
        const body = CreateProductSchema.parse(req.body);

        const b = await BusinessModel.findById(businessId);
        if (!b) return res.status(404).json({ error: 'not_found' });
        if (b.ownerId.toString() !== req.auth!.sub && !req.auth!.roles.includes('admin')) {
          return res.status(403).json({ error: 'forbidden' });
        }

        const p = await ProductModel.create({
          businessId,
          name: body.name,
          category: body.category ?? 'General',
          price: body.price,
          images: body.images,
          stock: body.stock,
          isActive: body.isActive,
        });

        return res.status(201).json({ id: p._id.toString() });
      } catch (e) {
        return next(e);
      }
    },
  );

  r.get('/:id/products', async (req, res) => {
    const businessId = req.params.id;
    const list = await ProductModel.find({ businessId, isActive: true }).sort({ createdAt: -1 });
    return res.json(
      list.map((p) => ({
        id: p._id.toString(),
        businessId: p.businessId.toString(),
        name: p.name,
        category: p.category ?? 'General',
        price: p.price,
        images: p.images,
        stock: p.stock,
        isActive: p.isActive,
      })),
    );
  });

  r.patch(
    '/products/:id',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res, next) => {
      try {
        const patch = PatchProductSchema.parse(req.body);
        const p = await ProductModel.findById(req.params.id);
        if (!p) return res.status(404).json({ error: 'not_found' });

        const b = await BusinessModel.findById(p.businessId);
        if (!b) return res.status(404).json({ error: 'not_found' });
        if (b.ownerId.toString() !== req.auth!.sub && !req.auth!.roles.includes('admin')) {
          return res.status(403).json({ error: 'forbidden' });
        }

        await ProductModel.updateOne({ _id: p._id }, { $set: patch });
        return res.json({ ok: true });
      } catch (e) {
        return next(e);
      }
    },
  );

  r.delete(
    '/products/:id',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res) => {
      const p = await ProductModel.findById(req.params.id);
      if (!p) return res.status(404).json({ error: 'not_found' });
      const b = await BusinessModel.findById(p.businessId);
      if (!b) return res.status(404).json({ error: 'not_found' });
      if (b.ownerId.toString() !== req.auth!.sub && !req.auth!.roles.includes('admin')) {
        return res.status(403).json({ error: 'forbidden' });
      }
      await ProductModel.deleteOne({ _id: p._id });
      return res.json({ ok: true });
    },
  );

  return r;
}

