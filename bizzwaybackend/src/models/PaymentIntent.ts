import mongoose, { Schema } from 'mongoose';

const PaymentIntentSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    orderId: { type: Schema.Types.ObjectId, ref: 'Order', required: false, index: true },
    /** order | subscription */
    purpose: { type: String, default: 'order', index: true },
    businessId: { type: Schema.Types.ObjectId, ref: 'Business', required: false, index: true },
    planId: { type: String, required: false, index: true },
    /** Our own reference (also pp_BillReference for Jazz) */
    clientTxnRef: { type: String, required: false, index: true, unique: true, sparse: true },
    amount: { type: Number, required: true },
    /** Amount in smallest unit when provider needs it (e.g. paisa for JazzCash) */
    amountMinor: { type: Number, required: false },
    currency: { type: String, required: true, default: 'PKR' },
    status: { type: String, required: true, default: 'created' }, // created|paid|failed|cancelled
    provider: { type: String, required: true, default: 'cod' }, // cod|jazzcash|easypaisa|stripe (future)
    providerRef: { type: String, required: false },
    lastProviderMessage: { type: String, required: false },
    lastProviderResponse: { type: Schema.Types.Mixed, required: false },
  },
  { timestamps: true },
);

export type PaymentIntentDoc = mongoose.InferSchemaType<typeof PaymentIntentSchema>;

export const PaymentIntentModel =
  (mongoose.models.PaymentIntent as mongoose.Model<PaymentIntentDoc> | undefined) ??
  mongoose.model<PaymentIntentDoc>('PaymentIntent', PaymentIntentSchema);

