import crypto from 'node:crypto';

import type { Env } from '../config/env.js';
import { publicAppBaseUrl } from '../config/urls.js';

/**
 * pp_SecureHash (JazzCash v4.2+ style, common in their merchant docs):
 * HMAC-SHA256 key = integrity salt, message = (integritySalt&key1=val1&key2=val2)
 * with keys sorted, only pp_* and excluding empty pp_SecureHash.
 */
export function buildJazzCashSecureHash(
  payload: Record<string, string | number | boolean | undefined | null>,
  integritySalt: string,
): string {
  const strPayload: Record<string, string> = {};
  for (const [k, v] of Object.entries(payload)) {
    if (k === 'pp_SecureHash') continue;
    if (!k.startsWith('pp_') && !k.startsWith('ppmpf')) continue;
    if (v === undefined || v === null) continue;
    strPayload[k] = String(v);
  }
  const sortedKeys = Object.keys(strPayload).sort();
  const dataString = sortedKeys.map((k) => `${k}=${strPayload[k]}`).join('&');
  const toBeHashed = integritySalt + '&' + dataString;
  return crypto
    .createHmac('sha256', integritySalt)
    .update(toBeHashed, 'utf8')
    .digest('hex')
    .toUpperCase();
}

function pkTxnDateTime(d = new Date()): string {
  // Match common Jazz examples: YYYYMMDDHHmmss (24h) — PKT
  const s = d.toLocaleString('en-GB', {
    timeZone: 'Asia/Karachi',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  });
  // en-GB: "DD/MM/YYYY, HH:mm:ss"
  const m = s.match(/(\d{2})\/(\d{2})\/(\d{4}), (\d{2}):(\d{2}):(\d{2})/);
  if (!m) {
    return d.toISOString().replace(/[-:T.Z]/g, '').slice(0, 14);
  }
  const [, day, mon, year, hh, mm, ss] = m;
  return `${year}${mon}${day}${hh}${mm}${ss}`;
}

function txnExpiry(d: Date, addMinutes: number) {
  return pkTxnDateTime(new Date(d.getTime() + addMinutes * 60_000));
}

export function jazzMwalletBaseUrl(sandbox: boolean) {
  return sandbox
    ? 'https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction'
    : 'https://payments.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction';
}

export function jazzIsConfigured(env: Env) {
  return Boolean(
    env.JAZZCASH_MERCHANT_ID && env.JAZZCASH_PASSWORD && env.JAZZCASH_INTEGRITY_SALT,
  );
}

type InitArgs = {
  amountPaisa: number;
  billReference: string;
  description: string;
  /** Stored on payment intent id / correlation */
  paymentIntentId: string;
  returnPath?: string; // default /api/payments/callbacks/jazzcash/return
};

/**
 * Returns JSON from Jazz (shape varies) — your mobile app or WebView should follow
 * any redirect URL the gateway returns.
 */
export async function initiateJazzMwallet(
  env: Env,
  args: InitArgs,
): Promise<{ data: unknown; rawText?: string; contentType: string }> {
  if (!jazzIsConfigured(env)) {
    throw new Error('JazzCash env missing (JAZZCASH_MERCHANT_ID / PASSWORD / INTEGRITY_SALT)');
  }
  const base = publicAppBaseUrl(env);
  const returnPath = args.returnPath ?? '/api/payments/callbacks/jazzcash/return';
  const pp_ReturnURL = `${base}${returnPath}`;

  const now = new Date();
  const params: Record<string, string> = {
    pp_Version: '1.1',
    pp_TxnType: 'MWALLET',
    pp_Language: 'EN',
    pp_MerchantID: env.JAZZCASH_MERCHANT_ID!,
    pp_Password: env.JAZZCASH_PASSWORD!,
    pp_TxnRefNo: `BZW${args.paymentIntentId.slice(-12)}${Date.now().toString(36)}`.slice(0, 20),
    pp_Amount: String(args.amountPaisa),
    pp_TxnCurrency: 'PKR',
    pp_TxnDateTime: pkTxnDateTime(now),
    pp_TxnExpiryDateTime: txnExpiry(now, 10080), // 7 days (sandbox-friendly)
    pp_BillReference: args.billReference.slice(0, 20),
    pp_Description: args.description.slice(0, 128),
    pp_ReturnURL: pp_ReturnURL,
    // merchant metadata / correlation
    ppmpf_1: args.paymentIntentId,
    ppmpf_2: 'subscription',
    ppmpf_3: '',
    ppmpf_4: '',
    ppmpf_5: '',
    pp_SecureHash: '',
  };

  params.pp_SecureHash = buildJazzCashSecureHash(params, env.JAZZCASH_INTEGRITY_SALT!);

  const body = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null) body.set(k, String(v));
  }

  const url = jazzMwalletBaseUrl(env.JAZZCASH_SANDBOX);
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const contentType = res.headers.get('content-type') ?? 'application/octet-stream';
  const text = await res.text();
  if (contentType.includes('application/json')) {
    try {
      return { data: JSON.parse(text) as unknown, contentType, rawText: text };
    } catch {
      return { data: { _raw: text }, contentType, rawText: text };
    }
  }
  return { data: { _raw: text }, contentType, rawText: text };
}

/** Best-effort success detection on DoMWallet JSON response. */
export function jazzResponseLooksSuccessful(data: unknown): boolean {
  if (!data || typeof data !== 'object') return false;
  const o = data as Record<string, unknown>;
  const code = o.pp_ResponseCode ?? o.responseCode;
  if (typeof code === 'string' && (code === '000' || code === '00' || code === '200')) return true;
  if (code === 0) return true;
  const success = o.success ?? o.PaymentStatus;
  if (success === true) return true;
  return false;
}

export function buildJazzReturnHash(
  body: Record<string, string | undefined>,
  integritySalt: string,
): string {
  return buildJazzCashSecureHash(body, integritySalt);
}
