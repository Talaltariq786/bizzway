import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { BusinessModel } from '../../models/Business.js';
import { OrderModel } from '../../models/Order.js';
import { ProductModel } from '../../models/Product.js';
import {
  ORDER_STATUSES_ACTIVE_FOR_RIDER,
  RIDER_MAX_CONCURRENT_ASSIGNMENTS,
} from '../../config/order_policy.js';
import { AssignRiderSchema, CreateOrderSchema, PatchOrderStatusSchema } from './orders.schemas.js';

export function ordersRouter(env: Env) {
  const r = Router();

  r.post('/', requireAuth(env), requireRoles('customer', 'admin'), async (req, res, next) => {
    try {
      const body = CreateOrderSchema.parse(req.body);
      const business = await BusinessModel.findById(body.businessId);
      if (!business) return res.status(404).json({ error: 'business_not_found' });

      const productIds = body.items.map((i) => i.productId);
      const products = await ProductModel.find({ _id: { $in: productIds }, businessId: body.businessId });
      const byId = new Map(products.map((p) => [p._id.toString(), p]));

      const items = body.items.map((i) => {
        const p = byId.get(i.productId);
        if (!p) throw new Error('invalid_product');
        return {
          productId: p._id,
          name: p.name,
          qty: i.qty,
          unitPrice: p.price,
        };
      });

      const subtotal = items.reduce((sum, it) => sum + it.qty * it.unitPrice, 0);
      const deliveryFee = 0;
      const total = subtotal + deliveryFee;

      const order = await OrderModel.create({
        customerId: req.auth!.sub,
        businessId: business._id,
        items,
        subtotal,
        deliveryFee,
        total,
        deliveryAddress: body.deliveryAddress,
        deliveryLocation:
          body.deliveryLat != null && body.deliveryLng != null
            ? { type: 'Point', coordinates: [body.deliveryLng, body.deliveryLat] }
            : undefined,
      });

      return res.status(201).json({ id: order._id.toString() });
    } catch (e) {
      return next(e);
    }
  });

  r.get('/', requireAuth(env), async (req, res) => {
    const roles = req.auth!.roles;
    const userId = req.auth!.sub;

    const filter: any = {};
    if (roles.includes('admin')) {
      // no filter
    } else if (roles.includes('customer')) {
      filter.customerId = userId;
    } else if (roles.includes('businessOwner')) {
      const businesses = await BusinessModel.find({ ownerId: userId }).select('_id');
      filter.businessId = { $in: businesses.map((b) => b._id) };
    } else if (roles.includes('rider')) {
      filter.assignedRiderId = userId;
    } else {
      // serviceWorker doesn't have orders in MVP
      filter.customerId = userId;
    }

    const list = await OrderModel.find(filter).sort({ createdAt: -1 }).limit(50);
    const bizIds = [...new Set(list.map((o) => o.businessId))];
    const bizDocs =
      bizIds.length > 0
        ? await BusinessModel.find({ _id: { $in: bizIds } }).select('type name')
        : [];
    const bizMeta = new Map(
      bizDocs.map((b) => [
        b._id.toString(),
        { type: b.type, name: b.name },
      ]),
    );

    return res.json(
      list.map((o) => {
        const meta = bizMeta.get(o.businessId.toString());
        return {
          id: o._id.toString(),
          customerId: o.customerId.toString(),
          businessId: o.businessId.toString(),
          businessType: meta?.type ?? '',
          businessName: meta?.name ?? '',
          items: o.items,
          subtotal: o.subtotal,
          deliveryFee: o.deliveryFee,
          total: o.total,
          status: o.status,
          deliveryAddress: o.deliveryAddress,
          assignedRiderId: o.assignedRiderId?.toString?.(),
          createdAt: o.createdAt,
          updatedAt: o.updatedAt,
        };
      }),
    );
  });

  r.patch(
    '/:id/status',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res, next) => {
      try {
        const body = PatchOrderStatusSchema.parse(req.body);
        const order = await OrderModel.findById(req.params.id);
        if (!order) return res.status(404).json({ error: 'not_found' });

        const business = await BusinessModel.findById(order.businessId);
        if (!business) return res.status(404).json({ error: 'not_found' });
        if (business.ownerId.toString() !== req.auth!.sub && !req.auth!.roles.includes('admin')) {
          return res.status(403).json({ error: 'forbidden' });
        }

        order.status = body.status;
        await order.save();
        return res.json({ ok: true });
      } catch (e) {
        return next(e);
      }
    },
  );

  r.post(
    '/:id/assign-rider',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res, next) => {
      try {
        const body = AssignRiderSchema.parse(req.body);
        const order = await OrderModel.findById(req.params.id);
        if (!order) return res.status(404).json({ error: 'not_found' });

        const business = await BusinessModel.findById(order.businessId);
        if (!business) return res.status(404).json({ error: 'not_found' });
        if (business.ownerId.toString() !== req.auth!.sub && !req.auth!.roles.includes('admin')) {
          return res.status(403).json({ error: 'forbidden' });
        }

        const alreadyForRider = await OrderModel.countDocuments({
          assignedRiderId: body.riderUserId,
          status: { $in: [...ORDER_STATUSES_ACTIVE_FOR_RIDER] },
          _id: { $ne: order._id },
        });
        if (alreadyForRider >= RIDER_MAX_CONCURRENT_ASSIGNMENTS) {
          return res.status(409).json({
            error: 'rider_max_active_orders',
            message:
              `Is rider ke paas pehle se ${RIDER_MAX_CONCURRENT_ASSIGNMENTS} active orders hain. ` +
              'Pehle deliver / complete karein, phir naya assign karein.',
          });
        }

        order.assignedRiderId = body.riderUserId as any;
        await order.save();
        return res.json({ ok: true });
      } catch (e) {
        return next(e);
      }
    },
  );

  return r;
}

