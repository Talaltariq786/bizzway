import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { BookingModel } from '../../models/Booking.js';
import { CreateBookingSchema, PatchBookingStatusSchema } from './bookings.schemas.js';

export function bookingsRouter(env: Env) {
  const r = Router();

  // Create booking (customer)
  r.post('/', requireAuth(env), requireRoles('customer', 'admin'), async (req, res, next) => {
    try {
      const body = CreateBookingSchema.parse(req.body);
      const dt = new Date(body.dateTime);
      if (Number.isNaN(dt.getTime())) {
        return res.status(400).json({ error: 'invalid_datetime' });
      }

      const b = await BookingModel.create({
        userId: req.auth!.sub,
        businessId: body.businessId as any,
        businessType: body.businessType,
        businessName: body.businessName,
        itemId: body.itemId,
        itemName: body.itemName,
        price: body.price,
        durationMinutes: body.durationMinutes,
        dateTime: dt,
        status: 'pending',
        notes: body.notes,
        customerFullName: body.customerFullName,
        customerNic: body.customerNic,
        customerLicenseNo: body.customerLicenseNo,
        bookingCode: body.bookingCode,
        vehicleHandoverMode: body.vehicleHandoverMode,
        rentacarTripType: body.rentacarTripType,
        pickupAddress: body.pickupAddress,
        dropoffAddress: body.dropoffAddress,
      });

      return res.status(201).json({ id: b._id.toString() });
    } catch (e) {
      return next(e);
    }
  });

  // List bookings (role filtered)
  r.get('/', requireAuth(env), async (req, res) => {
    const roles = req.auth!.roles;
    const userId = req.auth!.sub;
    const filter: any = {};

    if (roles.includes('admin')) {
      // no filter
    } else {
      // MVP: bookings are customer-owned; owner views can be added later by businessId mapping.
      filter.userId = userId;
    }

    const list = await BookingModel.find(filter).sort({ createdAt: -1 }).limit(50);
    return res.json({
      data: list.map((b) => ({
        id: b._id.toString(),
        businessId: b.businessId.toString(),
        businessName: b.businessName,
        businessTypeId: b.businessType,
        itemId: b.itemId,
        itemName: b.itemName,
        price: b.price,
        durationMinutes: b.durationMinutes,
        dateTime: b.dateTime,
        status: b.status,
        notes: b.notes,
        customerFullName: b.customerFullName,
        customerNic: b.customerNic,
        customerLicenseNo: b.customerLicenseNo,
        bookingCode: b.bookingCode,
        vehicleHandoverMode: b.vehicleHandoverMode,
        rentacarTripType: b.rentacarTripType,
        pickupAddress: b.pickupAddress,
        dropoffAddress: b.dropoffAddress,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      })),
    });
  });

  // Owner/admin: update status (stubbed owner checks for now)
  r.patch('/:id/status', requireAuth(env), requireRoles('businessOwner', 'admin'), async (req, res, next) => {
    try {
      const body = PatchBookingStatusSchema.parse(req.body);
      const b = await BookingModel.findById(req.params.id);
      if (!b) return res.status(404).json({ error: 'not_found' });
      b.status = body.status;
      await b.save();
      return res.json({ ok: true });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

