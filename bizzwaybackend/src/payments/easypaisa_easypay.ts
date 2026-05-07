import crypto from 'node:crypto';

import type { Env } from '../config/env.js';
import { publicAppBaseUrl } from '../config/urls.js';

export function easypayIsFormConfigured(env: Env) {
  return Boolean(
    env.EASYPAY_STORE_ID && env.EASYPAY_HASH_KEY && env.EASYPAY_FORM_POST_URL,
  );
}

/**
 * Telenor Easypay often expects a "merchantHash" (exact formula in your merchant PDF).
 * Default: HMAC-SHA256 over store|order|amountPaisa using HASH_KEY.
 * Replace in code if Telenor gives a different string order (MD5, etc.).
 */
export function buildEasypayMerchantHash(env: Env, orderId: string, amountPaisa: number) {
  const data = `${env.EASYPAY_STORE_ID}|${orderId}|${amountPaisa}`;
  return crypto.createHmac('sha256', env.EASYPAY_HASH_KEY!).update(data, 'utf8').digest('hex');
}

type CheckoutFieldsArgs = {
  orderId: string;
  amountPaisa: number;
  email?: string;
  mobile?: string;
  paymentIntentId: string;
};

/** Fields for a generic HTML form POST to EASYPAY_FORM_POST_URL (tune field names in portal). */
export function buildEasypayFormFields(
  env: Env,
  args: CheckoutFieldsArgs,
): Record<string, string> {
  if (!easypayIsFormConfigured(env)) {
    throw new Error('EasyPaisa form env missing (STORE_ID, HASH_KEY, FORM_POST_URL)');
  }
  const base = publicAppBaseUrl(env);
  const postback = `${base}/api/payments/callbacks/easypaisa/ipn`;
  const h = buildEasypayMerchantHash(env, args.orderId, args.amountPaisa);
  return {
    // Common Easypay-style names; confirm against your integration guide
    storeId: env.EASYPAY_STORE_ID!,
    orderId: args.orderId,
    amount: String(args.amountPaisa),
    /// Some deployments use paisa, some use rupees in integer — your doc decides
    postBackURL: postback,
    merchantHash: h,
    orderRef: args.paymentIntentId,
    merchantUserName: args.email ?? '',
    mobile: args.mobile ?? '',
  };
}

/**
 * IPN: compare body.skey or body.secure_key to an expected value you configure from Telenor,
 * or verify using EASYPAY_IPN_SKEY_VALUE (shared secret) + simple concat (override as needed).
 */
export function easypayIpnAcceptsInsecure(
  env: Env,
  body: Record<string, string | undefined>,
): { ok: boolean; reason: string } {
  if (env.NODE_ENV === 'production' && env.EASYPAY_IPN_INSECURE_DEV) {
    return { ok: false, reason: 'EASYPAY_IPN_INSECURE_DEV is forbidden in production' };
  }
  if (env.EASYPAY_IPN_SKEY_VALUE) {
    const got = body.skey ?? body.secure_key ?? body.SKEY;
    if (got && got === env.EASYPAY_IPN_SKEY_VALUE) {
      return { ok: true, reason: 'skey' };
    }
  }
  if (env.EASYPAY_IPN_INSECURE_DEV) {
    return { ok: true, reason: 'insecure_dev_bypass' };
  }
  return { ok: false, reason: 'Unable to verify IPN. Set EASYPAY_IPN_SKEY_VALUE or (dev) EASYPAY_IPN_INSECURE_DEV' };
}
