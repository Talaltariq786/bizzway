import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { UserModel } from '../../models/User.js';
import { requireAuth } from '../../middlewares/auth.js';
import { z } from 'zod';

const PatchMeSchema = z.object({
  name: z.string().min(1).optional(),
  avatarUrl: z.string().url().optional(),
  // Optional: customer saved addresses (app uses Home/Office/Other).
  addresses: z
    .array(
      z.object({
        id: z.string().min(1),
        label: z.string().min(1),
        address: z.string().min(1),
        lat: z.number().optional(),
        lng: z.number().optional(),
        isSelected: z.boolean().optional(),
      }),
    )
    .max(20)
    .optional(),
});

const AddressIdParam = z.object({ id: z.string().min(1) });

export function meRouter(env: Env) {
  const r = Router();

  r.get('/', requireAuth(env), async (req, res) => {
    const user = await UserModel.findById(req.auth!.sub);
    if (!user) return res.status(404).json({ error: 'not_found' });
    return res.json({
      id: user._id.toString(),
      phone: user.phone,
      email: user.email,
      roles: user.roles,
      name: user.name,
      avatarUrl: user.avatarUrl,
      addresses: (user as any).addresses ?? [],
    });
  });

  r.get('/addresses', requireAuth(env), async (req, res) => {
    const user = await UserModel.findById(req.auth!.sub);
    if (!user) return res.status(404).json({ error: 'not_found' });
    return res.json({ addresses: (user as any).addresses ?? [] });
  });

  r.post('/addresses', requireAuth(env), async (req, res, next) => {
    try {
      const body = z
        .object({
          id: z.string().min(1),
          label: z.string().min(1),
          address: z.string().min(1),
          lat: z.number().optional(),
          lng: z.number().optional(),
        })
        .parse(req.body);
      const user = await UserModel.findById(req.auth!.sub);
      if (!user) return res.status(404).json({ error: 'not_found' });
      const list = ((user as any).addresses ?? []) as any[];
      // First address becomes selected by default.
      const next = [
        ...list.map((a) => ({ ...a, isSelected: false })),
        { ...body, isSelected: list.length === 0 },
      ];
      (user as any).addresses = next;
      await user.save();
      return res.status(201).json({ addresses: (user as any).addresses ?? [] });
    } catch (e) {
      return next(e);
    }
  });

  r.patch('/addresses/:id/select', requireAuth(env), async (req, res, next) => {
    try {
      const { id } = AddressIdParam.parse(req.params);
      const user = await UserModel.findById(req.auth!.sub);
      if (!user) return res.status(404).json({ error: 'not_found' });
      const list = (((user as any).addresses ?? []) as any[]).map((a) => ({
        ...a,
        isSelected: a.id === id,
      }));
      if (!list.some((a) => a.id === id)) {
        return res.status(404).json({ error: 'not_found' });
      }
      (user as any).addresses = list;
      await user.save();
      return res.json({ addresses: (user as any).addresses ?? [] });
    } catch (e) {
      return next(e);
    }
  });

  r.delete('/addresses/:id', requireAuth(env), async (req, res, next) => {
    try {
      const { id } = AddressIdParam.parse(req.params);
      const user = await UserModel.findById(req.auth!.sub);
      if (!user) return res.status(404).json({ error: 'not_found' });
      const list = ((user as any).addresses ?? []) as any[];
      const next = list.filter((a) => a.id !== id);
      if (next.length === list.length) return res.status(404).json({ error: 'not_found' });
      // Ensure one selected.
      if (!next.some((a) => a.isSelected) && next.length > 0) {
        next[0] = { ...next[0], isSelected: true };
      }
      (user as any).addresses = next;
      await user.save();
      return res.json({ addresses: (user as any).addresses ?? [] });
    } catch (e) {
      return next(e);
    }
  });

  r.patch('/', requireAuth(env), async (req, res, next) => {
    try {
      const body = PatchMeSchema.parse(req.body);
      const user = await UserModel.findByIdAndUpdate(
        req.auth!.sub,
        { $set: body },
        { new: true },
      );
      if (!user) return res.status(404).json({ error: 'not_found' });
      return res.json({
        id: user._id.toString(),
        phone: user.phone,
        email: user.email,
        roles: user.roles,
        name: user.name,
        avatarUrl: user.avatarUrl,
        addresses: (user as any).addresses ?? [],
      });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

