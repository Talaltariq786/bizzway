import { z } from 'zod';

export const UpsertPushTokenSchema = z.object({
  token: z.string().min(20),
  platform: z.enum(['ios', 'android', 'web']),
  app: z.enum(['customer', 'business', 'riderServices']).default('customer'),
});

export const TestPushSchema = z.object({
  token: z.string().min(20),
  title: z.string().min(1).max(120).default('BizzWay'),
  body: z.string().min(1).max(600).default('Test notification'),
});

