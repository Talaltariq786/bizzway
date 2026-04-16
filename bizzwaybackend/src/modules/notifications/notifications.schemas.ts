import { z } from 'zod';

export const CreateNotificationSchema = z.object({
  title: z.string().min(1).max(120),
  body: z.string().min(1).max(600),
  kind: z.enum(['info', 'success', 'warning', 'error']).optional(),
  data: z.record(z.string(), z.any()).optional(),
});

export const MarkReadSchema = z.object({
  isRead: z.boolean(),
});

