import { z } from 'zod';

export const SubscriptionCheckoutSchema = z.object({
  businessId: z.string().min(1),
  planId: z.enum(['starter', 'pro', 'business']),
  provider: z.enum(['jazzcash', 'easypaisa']),
});
