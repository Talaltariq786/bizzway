import mongoose from 'mongoose';

import { findPlanById } from '../../config/subscription_plans.js';
import { BusinessModel } from '../../models/Business.js';
import { PaymentIntentModel } from '../../models/PaymentIntent.js';

function addDays(d: Date, days: number) {
  return new Date(d.getTime() + days * 86_400_000);
}

export async function markSubscriptionPaid(args: {
  paymentIntentId: string;
  provider: string;
  providerRef: string;
  lastMessage?: string;
}) {
  const pi = await PaymentIntentModel.findById(args.paymentIntentId);
  if (!pi) {
    return { ok: false as const, reason: 'payment_intent_not_found' };
  }
  if (pi.purpose !== 'subscription' || !pi.businessId) {
    return { ok: false as const, reason: 'not_a_subscription' };
  }
  if (pi.status === 'paid') {
    return { ok: true as const, businessId: pi.businessId.toString(), alreadyPaid: true };
  }

  const plan = findPlanById(String(pi.planId));
  if (!plan) {
    return { ok: false as const, reason: 'invalid_plan' };
  }

  const b = await BusinessModel.findById(pi.businessId);
  if (!b) {
    return { ok: false as const, reason: 'business_not_found' };
  }

  const now = new Date();
  const base = b.subscriptionExpiresAt && b.subscriptionExpiresAt > now ? b.subscriptionExpiresAt : now;
  const newExpiry = addDays(base, plan.periodDays);

  await PaymentIntentModel.updateOne(
    { _id: pi._id },
    {
      $set: {
        status: 'paid',
        provider: args.provider,
        providerRef: args.providerRef,
        lastProviderMessage: args.lastMessage,
      },
    },
  );

  await BusinessModel.updateOne(
    { _id: b._id },
    {
      $set: {
        subscriptionPlan: String(pi.planId),
        subscriptionExpiresAt: newExpiry,
        subscriptionLastProvider: args.provider,
        subscriptionLastPaymentIntentId: pi._id,
      },
    },
  );

  return { ok: true as const, businessId: b._id.toString(), expiresAt: newExpiry };
}

export function parseJazzCallbackSuccess(
  body: Record<string, string | undefined>,
): { ok: boolean; message?: string } {
  const code = body.pp_ResponseCode;
  if (code === '000' || code === '00' || code === '200') {
    return { ok: true };
  }
  if (code) {
    return { ok: false, message: `pp_ResponseCode=${code} ${body.pp_ResponseMessage ?? ''}`.trim() };
  }
  // Some responses omit code when pending — treat as failure for subscription unless explicit success
  return { ok: false, message: 'Missing pp_ResponseCode' };
}

export function parseEasypaisaIpnStatus(
  body: Record<string, string | undefined>,
): { ok: boolean; orderId?: string; txRef?: string; statusRaw?: string } {
  const orderId = body.orderid ?? body.orderId ?? body.OrderId;
  const tx = body.tranID ?? body.trans_id ?? body.transactionId;
  const st = (body.status ?? body.errCode ?? body.transaction_status ?? '') + '';
  // Common: "000" = paid (Telenor docs; confirm in your PDF)
  const success = st === '000' || st === '00' || st.toLowerCase() === 'paid' || st === 'success';
  return { ok: success, orderId, txRef: tx, statusRaw: st };
}

export function isObjectIdString(s: string) {
  return mongoose.Types.ObjectId.isValid(s) && new mongoose.Types.ObjectId(s).toString() === s;
}
