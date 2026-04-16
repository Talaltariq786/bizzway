import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { NotificationModel } from '../../models/Notification.js';
import { CreateNotificationSchema, MarkReadSchema } from './notifications.schemas.js';

export function notificationsRouter(env: Env) {
  const r = Router();

  // List my notifications
  r.get('/notifications', requireAuth(env), async (req, res) => {
    const list = await NotificationModel.find({ userId: req.auth!.sub })
      .sort({ createdAt: -1 })
      .limit(50);
    return res.json({
      data: list.map((n) => ({
        id: n._id.toString(),
        title: n.title,
        body: n.body,
        kind: n.kind,
        isRead: n.isRead,
        data: n.data ?? null,
        createdAt: n.createdAt,
      })),
    });
  });

  // Create (server-side only; useful for admin/testing)
  r.post('/notifications', requireAuth(env), async (req, res, next) => {
    try {
      const body = CreateNotificationSchema.parse(req.body);
      const n = await NotificationModel.create({
        userId: req.auth!.sub,
        title: body.title,
        body: body.body,
        kind: body.kind ?? 'info',
        data: body.data,
      });
      return res.status(201).json({ id: n._id.toString() });
    } catch (e) {
      return next(e);
    }
  });

  // Mark read/unread
  r.patch('/notifications/:id', requireAuth(env), async (req, res, next) => {
    try {
      const body = MarkReadSchema.parse(req.body);
      const n = await NotificationModel.findById(req.params.id);
      if (!n) return res.status(404).json({ error: 'not_found' });
      if (n.userId.toString() !== req.auth!.sub) return res.status(403).json({ error: 'forbidden' });
      n.isRead = body.isRead;
      await n.save();
      return res.json({ ok: true });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

