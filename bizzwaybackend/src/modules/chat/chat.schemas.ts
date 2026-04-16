import { z } from 'zod';

export const CreateChatSchema = z.object({
  participantUserId: z.string().min(10),
  type: z.enum(['customer_owner', 'customer_rider']),
});

export const SendMessageSchema = z.object({
  text: z.string().min(1).max(2000),
});

