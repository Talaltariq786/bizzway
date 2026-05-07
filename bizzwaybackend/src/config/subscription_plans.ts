/** PKR + duration for merchant (business) subscription. Amount sent to JazzCash in paisa. */
export const MERCHANT_SUBSCRIPTION_PLANS = [
  { id: 'starter', label: 'Starter', amountPkr: 999, periodDays: 30, description: 'Ziyada products + support' },
  { id: 'pro', label: 'Pro', amountPkr: 2499, periodDays: 30, description: 'Advanced tools' },
  { id: 'business', label: 'Business', amountPkr: 4999, periodDays: 30, description: 'Full suite' },
] as const;

export type SubscriptionPlanId = (typeof MERCHANT_SUBSCRIPTION_PLANS)[number]['id'];

export function findPlanById(id: string) {
  return MERCHANT_SUBSCRIPTION_PLANS.find((p) => p.id === id);
}

export function pkrToPaisa(pkr: number) {
  return Math.round(pkr * 100);
}
