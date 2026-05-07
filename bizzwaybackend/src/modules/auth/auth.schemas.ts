import { z } from 'zod';

export const RegisterSchema = z
  .object({
    phone: z.string().min(10).max(20).optional(),
    email: z.string().email().max(200).optional(),
    password: z.string().min(6).max(200),
    role: z
      .enum(['customer', 'businessOwner', 'rider', 'serviceWorker'])
      .default('customer'),
    name: z.string().trim().min(2).max(120),
  })
  .refine((d) => !!(d.phone?.trim() || d.email?.trim()), {
    message: 'phone_or_email_required',
    path: ['phone'],
  });

export const LoginSchema = z.object({
  identifier: z.string().min(3),
  password: z.string().min(6),
});

export const RefreshSchema = z.object({
  refreshToken: z.string().min(10),
});

