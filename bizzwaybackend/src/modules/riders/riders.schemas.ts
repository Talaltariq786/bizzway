import { z } from 'zod';

export const UpsertRiderProfileSchema = z.object({
  licenseNo: z.string().min(3).max(80),
  nic: z.string().min(5).max(40),
  bikeNumber: z.string().min(2).max(40),
  walletAmount: z.number().min(0).optional(),
  planId: z.string().min(1).max(40).optional(),
});

