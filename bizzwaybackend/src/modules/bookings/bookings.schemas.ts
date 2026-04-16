import { z } from 'zod';

export const CreateBookingSchema = z.object({
  businessId: z.string().min(1),
  businessType: z.string().min(1),
  businessName: z.string().min(1),
  itemId: z.string().min(1),
  itemName: z.string().min(1),
  price: z.number().nonnegative(),
  durationMinutes: z.number().int().positive().optional(),
  dateTime: z.string().min(4), // ISO string
  notes: z.string().max(500).optional(),

  // Optional rent-a-car fields
  customerFullName: z.string().max(120).optional(),
  customerNic: z.string().max(40).optional(),
  customerLicenseNo: z.string().max(60).optional(),
  bookingCode: z.string().max(40).optional(),
  vehicleHandoverMode: z.string().max(40).optional(),
  rentacarTripType: z.string().max(40).optional(),
  pickupAddress: z.string().max(240).optional(),
  dropoffAddress: z.string().max(240).optional(),
});

export const PatchBookingStatusSchema = z.object({
  status: z.enum(['pending', 'confirmed', 'completed', 'cancelled']),
});

