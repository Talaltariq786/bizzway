import { z } from 'zod';

export const CreateOrderSchema = z.object({
  businessId: z.string().min(10),
  items: z.array(
    z.object({
      productId: z.string().min(10),
      qty: z.number().int().min(1),
    }),
  ).min(1),
  deliveryAddress: z.string().min(1).optional(),
  deliveryLat: z.number().min(-90).max(90).optional(),
  deliveryLng: z.number().min(-180).max(180).optional(),
});

export const PatchOrderStatusSchema = z.object({
  status: z.enum(['pending', 'accepted', 'preparing', 'ready', 'picked', 'delivered', 'cancelled']),
});

export const AssignRiderSchema = z.object({
  riderUserId: z.string().min(10),
});

