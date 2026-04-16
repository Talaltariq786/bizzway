import { z } from 'zod';

export const CreateUploadSchema = z.object({
  purpose: z.enum(['product_image', 'profile_image', 'document', 'prescription']).default('product_image'),
  filename: z.string().min(1).max(200).optional(),
  contentType: z.string().min(1).max(120).optional(),
});

