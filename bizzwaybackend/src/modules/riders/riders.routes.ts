import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { OrderModel } from '../../models/Order.js';
import { RiderModel } from '../../models/Rider.js';
import { UpsertRiderProfileSchema } from './riders.schemas.js';

export function ridersRouter(env: Env) {
  const r = Router();

  // Rider profile (me)
  r.get('/riders/me', requireAuth(env), requireRoles('rider', 'admin'), async (req, res) => {
    const doc = await RiderModel.findOne({ userId: req.auth!.sub });
    return res.json({
      rider: doc
        ? {
            userId: doc.userId.toString(),
            businessId: doc.businessId?.toString?.() ?? null,
            licenseNo: doc.licenseNo ?? null,
            nic: doc.nic ?? null,
            bikeNumber: doc.bikeNumber ?? null,
            walletAmount: doc.walletAmount ?? 0,
            planId: doc.planId ?? null,
            online: doc.online ?? false,
            location: doc.location ?? null,
            lastSeenAt: doc.lastSeenAt ?? null,
          }
        : null,
    });
  });

  // Upsert rider profile (from app after signup)
  r.put('/riders/me', requireAuth(env), requireRoles('rider', 'admin'), async (req, res, next) => {
    try {
      const body = UpsertRiderProfileSchema.parse(req.body);
      await RiderModel.updateOne(
        { userId: req.auth!.sub },
        {
          $set: {
            licenseNo: body.licenseNo,
            nic: body.nic,
            bikeNumber: body.bikeNumber,
            walletAmount: body.walletAmount ?? 0,
            planId: body.planId ?? 'rider_monthly',
          },
        },
        { upsert: true },
      );
      const doc = await RiderModel.findOne({ userId: req.auth!.sub });
      return res.json({
        ok: true,
        rider: doc
          ? {
              userId: doc.userId.toString(),
              licenseNo: doc.licenseNo ?? null,
              nic: doc.nic ?? null,
              bikeNumber: doc.bikeNumber ?? null,
              walletAmount: doc.walletAmount ?? 0,
              planId: doc.planId ?? null,
            }
          : null,
      });
    } catch (e) {
      return next(e);
    }
  });

  // Rider: assigned orders
  r.get('/riders/me/orders', requireAuth(env), requireRoles('rider', 'admin'), async (req, res) => {
    const list = await OrderModel.find({ assignedRiderId: req.auth!.sub }).sort({ createdAt: -1 }).limit(50);
    return res.json({
      orders: list.map((o) => ({
        id: o._id.toString(),
        customerId: o.customerId.toString(),
        businessId: o.businessId.toString(),
        items: o.items,
        subtotal: o.subtotal,
        deliveryFee: o.deliveryFee,
        total: o.total,
        status: o.status,
        deliveryAddress: o.deliveryAddress,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
      })),
    });
  });

  return r;
}

