import mongoose, { Schema } from 'mongoose';

const PaymentIntentSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    orderId: { type: Schema.Types.ObjectId, ref: 'Order', required: false, index: true },
    amount: { type: Number, required: true },
    currency: { type: String, required: true, default: 'PKR' },
    status: { type: String, required: true, default: 'created' }, // created|paid|failed|cancelled
    provider: { type: String, required: true, default: 'cod' }, // cod|jazzcash|easypaisa|stripe (future)
    providerRef: { type: String, required: false },
  },
  { timestamps: true },
);

export type PaymentIntentDoc = mongoose.InferSchemaType<typeof PaymentIntentSchema>;

export const PaymentIntentModel =
  (mongoose.models.PaymentIntent as mongoose.Model<PaymentIntentDoc> | undefined) ??
  mongoose.model<PaymentIntentDoc>('PaymentIntent', PaymentIntentSchema);

