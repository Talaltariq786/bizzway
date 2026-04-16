import { z } from 'zod';

export const RegisterSchema = z.object({
  phone: z.string().min(10).optional(),
  email: z.string().email().optional(),
  password: z.string().min(6),
  role: z.enum(['customer', 'businessOwner', 'rider', 'serviceWorker']).default('customer'),
  name: z.string().min(1).optional(),
});

export const LoginSchema = z.object({
  identifier: z.string().min(3),
  password: z.string().min(6),
});

export const RefreshSchema = z.object({
  refreshToken: z.string().min(10),
});

