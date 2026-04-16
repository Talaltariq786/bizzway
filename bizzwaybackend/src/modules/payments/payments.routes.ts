import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { PaymentIntentModel } from '../../models/PaymentIntent.js';
import { CreatePaymentIntentSchema, MarkPaymentSchema } from './payments.schemas.js';

export function paymentsRouter(env: Env) {
  const r = Router();

  // Create a payment intent (MVP stub: stores record only; real provider integration later)
  r.post('/payments/intents', requireAuth(env), async (req, res, next) => {
    try {
      const body = CreatePaymentIntentSchema.parse(req.body);
      const pi = await PaymentIntentModel.create({
        userId: req.auth!.sub,
        orderId: body.orderId ? (body.orderId as any) : undefined,
        amount: body.amount,
        currency: body.currency ?? 'PKR',
        provider: body.provider ?? 'cod',
        status: 'created',
      });
      return res.status(201).json({
        id: pi._id.toString(),
        status: pi.status,
        provider: pi.provider,
      });
    } catch (e) {
      return next(e);
    }
  });

  // Mark intent (server-side hook / admin / demo)
  r.patch('/payments/intents/:id', requireAuth(env), async (req, res, next) => {
    try {
      const body = MarkPaymentSchema.parse(req.body);
      const pi = await PaymentIntentModel.findById(req.params.id);
      if (!pi) return res.status(404).json({ error: 'not_found' });
      if (pi.userId.toString() !== req.auth!.sub) return res.status(403).json({ error: 'forbidden' });
      pi.status = body.status;
      pi.providerRef = body.providerRef;
      await pi.save();
      return res.json({ ok: true });
    } catch (e) {
      return next(e);
    }
  });

  // List my intents
  r.get('/payments/intents', requireAuth(env), async (req, res) => {
    const list = await PaymentIntentModel.find({ userId: req.auth!.sub }).sort({ createdAt: -1 }).limit(50);
    return res.json({
      data: list.map((pi) => ({
        id: pi._id.toString(),
        orderId: pi.orderId?.toString?.(),
        amount: pi.amount,
        currency: pi.currency,
        provider: pi.provider,
        status: pi.status,
        providerRef: pi.providerRef ?? null,
        createdAt: pi.createdAt,
      })),
    });
  });

  return r;
}

