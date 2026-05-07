import { randomUUID } from 'node:crypto';
import { Router } from 'express';

import type { Env } from '../../config/env.js';
import { MERCHANT_SUBSCRIPTION_PLANS, findPlanById, pkrToPaisa } from '../../config/subscription_plans.js';
import { publicAppBaseUrl } from '../../config/urls.js';
import {
  buildEasypayFormFields,
  easypayIpnAcceptsInsecure,
  easypayIsFormConfigured,
} from '../../payments/easypaisa_easypay.js';
import {
  buildJazzReturnHash,
  initiateJazzMwallet,
  jazzIsConfigured,
  jazzMwalletBaseUrl,
  jazzResponseLooksSuccessful,
} from '../../payments/jazzcash_mwallet.js';
import { BusinessModel } from '../../models/Business.js';
import { PaymentIntentModel } from '../../models/PaymentIntent.js';
import { requireAuth } from '../../middlewares/auth.js';
import { requireRoles } from '../../middlewares/roles.js';
import { SubscriptionCheckoutSchema } from './subscriptions.schemas.js';
import {
  isObjectIdString,
  markSubscriptionPaid,
  parseEasypaisaIpnStatus,
  parseJazzCallbackSuccess,
} from './subscriptions.service.js';

function successHtml(redirect: string | undefined) {
  const r = redirect
    ? `<p>Redirecting…</p><script>setTimeout(function(){location.replace(${JSON.stringify(redirect)});},800);</script>`
    : '<p>Payment result received. You can close this window.</p>';
  return `<!DOCTYPE html><html><head><meta charset="utf-8"/><title>Payment</title></head><body>${r}</body></html>`;
}

export function subscriptionsRouter(env: Env) {
  const r = Router();

  r.get('/subscriptions/plans', (_req, res) => {
    return res.json({
      plans: MERCHANT_SUBSCRIPTION_PLANS.map((p) => ({
        id: p.id,
        label: p.label,
        amountPkr: p.amountPkr,
        periodDays: p.periodDays,
        description: p.description,
      })),
    });
  });

  r.get(
    '/subscriptions/status',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res) => {
      const businessId = typeof req.query.businessId === 'string' ? req.query.businessId : '';
      if (!isObjectIdString(businessId)) {
        return res.status(400).json({ error: 'invalid_businessId' });
      }
      const b = await BusinessModel.findById(businessId);
      if (!b) return res.status(404).json({ error: 'not_found' });
      if (b.ownerId.toString() !== req.auth!.sub && !req.auth!.roles.includes('admin')) {
        return res.status(403).json({ error: 'forbidden' });
      }
      return res.json({
        subscriptionPlan: b.subscriptionPlan ?? 'free',
        subscriptionExpiresAt: b.subscriptionExpiresAt ?? null,
      });
    },
  );

  r.post(
    '/subscriptions/checkout',
    requireAuth(env),
    requireRoles('businessOwner', 'admin'),
    async (req, res, next) => {
      try {
        const body = SubscriptionCheckoutSchema.parse(req.body);
        if (env.PAYMENTS_MOCK_SUCCESS) {
          const plan = findPlanById(body.planId);
          if (!plan) return res.status(400).json({ error: 'invalid_plan' });
          const b = await BusinessModel.findById(body.businessId);
          if (!b) return res.status(404).json({ error: 'not_found' });
          if (b.ownerId.toString() !== req.auth!.sub) {
            return res.status(403).json({ error: 'forbidden' });
          }
          const ref = `mock-${randomUUID()}`;
          const pi = await PaymentIntentModel.create({
            userId: req.auth!.sub,
            purpose: 'subscription',
            businessId: b._id,
            planId: body.planId,
            clientTxnRef: ref,
            amount: plan.amountPkr,
            amountMinor: pkrToPaisa(plan.amountPkr),
            currency: 'PKR',
            status: 'created',
            provider: body.provider,
          });
          await markSubscriptionPaid({
            paymentIntentId: pi._id.toString(),
            provider: 'mock',
            providerRef: ref,
            lastMessage: 'PAYMENTS_MOCK_SUCCESS',
          });
          return res.status(201).json({ mock: true, paymentIntentId: pi._id.toString() });
        }

        const plan = findPlanById(body.planId);
        if (!plan) return res.status(400).json({ error: 'invalid_plan' });
        const b = await BusinessModel.findById(body.businessId);
        if (!b) return res.status(404).json({ error: 'not_found' });
        if (b.ownerId.toString() !== req.auth!.sub) {
          return res.status(403).json({ error: 'forbidden' });
        }

        const ref = `BIZ${Date.now().toString(36)}${randomUUID().replace(/-/g, '').slice(0, 8)}`.slice(0, 32);

        const pi = await PaymentIntentModel.create({
          userId: req.auth!.sub,
          purpose: 'subscription',
          businessId: b._id,
          planId: body.planId,
          clientTxnRef: ref,
          amount: plan.amountPkr,
          amountMinor: pkrToPaisa(plan.amountPkr),
          currency: 'PKR',
          status: 'created',
          provider: body.provider,
        });

        if (body.provider === 'jazzcash') {
          if (!jazzIsConfigured(env)) {
            return res.status(503).json({
              error: 'jazzcash_not_configured',
              message: 'Set JAZZCASH_MERCHANT_ID, JAZZCASH_PASSWORD, JAZZCASH_INTEGRITY_SALT in .env',
            });
          }
          const out = await initiateJazzMwallet(env, {
            amountPaisa: pkrToPaisa(plan.amountPkr),
            billReference: ref,
            description: `Bizzway ${plan.label} (${plan.periodDays}d)`,
            paymentIntentId: pi._id.toString(),
          });
          const ok = jazzResponseLooksSuccessful(out.data);
          await PaymentIntentModel.updateOne(
            { _id: pi._id },
            {
              $set: {
                lastProviderResponse: out.data,
                lastProviderMessage: `contentType=${out.contentType}:init`,
              },
            },
          );
          return res.status(201).json({
            paymentIntentId: pi._id.toString(),
            clientTxnRef: ref,
            provider: 'jazzcash',
            jazzcash: {
              apiUrl: jazzMwalletBaseUrl(env.JAZZCASH_SANDBOX),
              response: out.data,
              responseRaw: out.rawText,
              contentType: out.contentType,
              hint:
                'Open JazzCash return URL or WebView as per gateway response. Verify pp_ResponseCode on your side.',
              mayNeedCustomerStep: !ok,
            },
          });
        }

        if (body.provider === 'easypaisa') {
          if (!easypayIsFormConfigured(env)) {
            return res.status(503).json({
              error: 'easypaisa_not_configured',
              message:
                'Set EASYPAY_STORE_ID, EASYPAY_HASH_KEY, EASYPAY_FORM_POST_URL. Tune merchantHash in easypaisa_easypay.ts per Telenor guide.',
            });
          }
          const fields = buildEasypayFormFields(env, {
            orderId: ref,
            amountPaisa: pkrToPaisa(plan.amountPkr),
            paymentIntentId: pi._id.toString(),
          });
          return res.status(201).json({
            paymentIntentId: pi._id.toString(),
            clientTxnRef: ref,
            provider: 'easypaisa',
            easypaisa: {
              postUrl: env.EASYPAY_FORM_POST_URL!,
              method: 'POST',
              contentType: 'application/x-www-form-urlencoded',
              fields,
              postBackUrl: `${publicAppBaseUrl(env)}/api/payments/callbacks/easypaisa/ipn`,
              note:
                'POST this form from app WebView. Field names may need to match the Easypay guide from your portal.',
            },
          });
        }

        return res.status(400).json({ error: 'unsupported_provider' });
      } catch (e) {
        return next(e);
      }
    },
  );

  r.post('/payments/callbacks/jazzcash/return', async (req, res) => {
    const body = req.body as Record<string, string | undefined>;
    const redirect = env.PAYMENT_SUCCESS_REDIRECT
      ? `${env.PAYMENT_SUCCESS_REDIRECT}${env.PAYMENT_SUCCESS_REDIRECT.includes('?') ? '&' : '?'}jazz=1`
      : undefined;

    try {
      if (
        env.JAZZCASH_INTEGRITY_SALT &&
        body.pp_SecureHash &&
        !env.JAZZCASH_SKIP_RETURN_HASH_VERIFY
      ) {
        const our = buildJazzReturnHash(
          body as Record<string, string | undefined>,
          env.JAZZCASH_INTEGRITY_SALT,
        );
        const got = String(body.pp_SecureHash);
        if (our !== got.toUpperCase() && our !== got) {
          return res.status(400).type('html').send('<!DOCTYPE html><html><body>Invalid payment signature</body></html>');
        }
      }

      const { ok, message } = parseJazzCallbackSuccess(body);
      const piId = body.ppmpf_1;
      if (!isObjectIdString(String(piId ?? ''))) {
        return res.status(400).type('html').send(successHtml(redirect));
      }
      if (!ok) {
        if (message) {
          await PaymentIntentModel.findByIdAndUpdate(piId, { $set: { lastProviderMessage: message, status: 'failed' } });
        }
        return res.status(200).type('html').send(successHtml(redirect));
      }

      const provRef = String(body.pp_TxnRefNo ?? body.trans_id ?? body.pp_RetreivalReferenceNo ?? 'jazz');
      const out = await markSubscriptionPaid({
        paymentIntentId: String(piId),
        provider: 'jazzcash',
        providerRef: provRef,
        lastMessage: 'return_callback',
      });
      if (!out.ok) {
        return res.status(200).type('html').send(successHtml(redirect));
      }
      return res.status(200).type('html').send(successHtml(redirect));
    } catch (e) {
      console.error('[jazzcash return]', e);
      return res.status(200).type('html').send(successHtml(redirect));
    }
  });

  r.post('/payments/callbacks/easypaisa/ipn', async (req, res) => {
    const body: Record<string, string> = {};
    if (req.body && typeof req.body === 'object' && !Array.isArray(req.body)) {
      for (const [k, v] of Object.entries(req.body as Record<string, unknown>)) {
        body[k] = v == null ? '' : String(v);
      }
    }
    for (const [k, v] of Object.entries(req.query)) {
      if (typeof v === 'string') body[k] = v;
    }
    if (Object.keys(body).length === 0) {
      return res.status(400).send('NO_PARAMS');
    }

    const verify = easypayIpnAcceptsInsecure(env, body);
    if (!verify.ok) {
      if (env.NODE_ENV !== 'production') {
        console.warn('[easypaisa ipn] blocked:', verify.reason);
      }
      return res.status(401).send('UNAUTHORIZED');
    }

    const st = parseEasypaisaIpnStatus(body);
    const orderRef = st.orderId;
    if (!orderRef) {
      return res.status(400).send('NO_ORDER');
    }
    const pi = await PaymentIntentModel.findOne({ clientTxnRef: orderRef, purpose: 'subscription' });
    if (!pi) {
      return res.status(404).send('NOT_FOUND');
    }
    if (!st.ok) {
      await PaymentIntentModel.updateOne(
        { _id: pi._id },
        { $set: { lastProviderMessage: st.statusRaw ?? 'failed', status: 'failed' } },
      );
      return res.send('ACK_FAIL');
    }

    await markSubscriptionPaid({
      paymentIntentId: pi._id.toString(),
      provider: 'easypaisa',
      providerRef: st.txRef ?? 'easypay',
      lastMessage: st.statusRaw,
    });
    // Many Telenor callbacks expect a plain acknowledgment string
    return res.send('CBTOKEN:MPSTATOK');
  });

  return r;
}
