import { z } from 'zod';

export const CreateBusinessSchema = z.object({
  name: z.string().min(1),
  type: z.string().min(1).optional(),
  address: z.string().min(1).optional(),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export const CreateProductSchema = z.object({
  name: z.string().min(1),
  category: z.string().min(1).optional(),
  price: z.number().nonnegative(),
  images: z.array(z.string().min(1)).optional().default([]),
  stock: z.number().int().nonnegative().optional().default(0),
  isActive: z.boolean().optional().default(true),
});

export const PatchProductSchema = CreateProductSchema.partial();

