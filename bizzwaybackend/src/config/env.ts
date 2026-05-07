import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.string().optional().default('development'),
  PORT: z.coerce.number().int().positive().default(8080),
  MONGODB_URI: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(16),
  JWT_REFRESH_SECRET: z.string().min(16),
  JWT_ACCESS_TTL: z.string().min(1).default('15m'),
  JWT_REFRESH_TTL: z.string().min(1).default('30d'),
  CORS_ORIGIN: z.string().optional(),
  // Firebase Admin (FCM). Provide either JSON string or a file path.
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().optional(),
  FIREBASE_SERVICE_ACCOUNT_PATH: z.string().optional(),
  FIREBASE_PROJECT_ID: z.string().optional(),

  /** Public base URL for payment return/IPN (https://api.yourdomain.com). Fallback: localhost in dev. */
  PUBLIC_APP_BASE_URL: z.string().url().optional(),
  /**
   * After JazzCash return / EasyPaisa (browser) — optional app deep link.
   * Example: bizzway://payment-success
   */
  PAYMENT_SUCCESS_REDIRECT: z.string().min(1).max(2000).optional(),

  /** Dev only: mark subscription payments successful without calling gateways. */
  PAYMENTS_MOCK_SUCCESS: z.coerce.boolean().optional().default(false),

  // JazzCash (MWallet / v4.2 style — credentials from Jazz merchant portal)
  JAZZCASH_SANDBOX: z.coerce.boolean().optional().default(true),
  JAZZCASH_MERCHANT_ID: z.string().optional(),
  JAZZCASH_PASSWORD: z.string().optional(),
  JAZZCASH_INTEGRITY_SALT: z.string().optional(),
  /** Dev only: accept Jazz return without HMAC (do not use in production). */
  JAZZCASH_SKIP_RETURN_HASH_VERIFY: z.coerce.boolean().optional().default(false),

  /**
   * EasyPaisa (Easypay) — see merchant "Integration Guide" in portal. Values vary by product.
   * Start with these; Telenor may give different field names for hash/IPN.
   */
  EASYPAY_SANDBOX: z.coerce.boolean().optional().default(true),
  EASYPAY_STORE_ID: z.string().optional(),
  EASYPAY_HASH_KEY: z.string().optional(),
  EASYPAY_FORM_POST_URL: z.string().url().optional(),
  /**
   * When IPN skey/secure_key matches: sha256(orderId+amount+...).
   * If unset, EASYPAY_IPN_INSECURE_DEV=1 allows IPN in non-production.
   */
  EASYPAY_IPN_SKEY_VALUE: z.string().optional(),
  EASYPAY_IPN_INSECURE_DEV: z.coerce.boolean().optional().default(false),
});

export type Env = z.infer<typeof EnvSchema>;

export function loadEnv(raw: NodeJS.ProcessEnv): Env {
  const parsed = EnvSchema.safeParse(raw);
  if (!parsed.success) {
    const msg = parsed.error.issues
      .map((i) => `${i.path.join('.')}: ${i.message}`)
      .join('\n');
    throw new Error(`Invalid environment variables:\n${msg}`);
  }
  return parsed.data;
}

