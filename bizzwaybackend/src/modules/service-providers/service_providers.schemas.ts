import { z } from 'zod';

const ScrapRatesDisplaySchema = z
  .record(z.string().max(80), z.string().max(200))
  .optional();

export const UpsertServiceProviderProfileSchema = z.object({
  profession: z.string().min(2).max(80),
  nic: z.string().min(5).max(40).optional(),
  imageUrl: z.string().url().optional(),
  planId: z.string().min(1).max(40).optional(),
  scrapRatesDisplay: ScrapRatesDisplaySchema,
});

