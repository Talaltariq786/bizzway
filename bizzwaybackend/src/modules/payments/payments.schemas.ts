import { z } from 'zod';

export const CreatePaymentIntentSchema = z.object({
  amount: z.number().positive(),
  currency: z.string().min(1).max(8).optional(), // default PKR
  provider: z.enum(['cod', 'jazzcash', 'easypaisa', 'stripe']).optional(),
  orderId: z.string().optional(),
});

export const MarkPaymentSchema = z.object({
  status: z.enum(['paid', 'failed', 'cancelled']),
  providerRef: z.string().max(120).optional(),
});

