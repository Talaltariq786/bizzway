import mongoose, { Schema } from 'mongoose';

const PointSchema = new Schema(
  {
    type: { type: String, enum: ['Point'], required: true, default: 'Point' },
    coordinates: {
      type: [Number],
      required: true,
      // [lng, lat]
      validate: {
        validator: (v: number[]) => Array.isArray(v) && v.length === 2,
        message: 'coordinates must be [lng, lat]',
      },
    },
  },
  { _id: false },
);

const BusinessSchema = new Schema(
  {
    ownerId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, index: true },
    type: { type: String, index: true }, // grocery/restaurant/etc
    address: { type: String },
    location: { type: PointSchema, required: true },
    /** 'free' | 'starter' | 'pro' | 'business' — see subscription_plans config */
    subscriptionPlan: { type: String, default: 'free', index: true },
    subscriptionExpiresAt: { type: Date },
    subscriptionLastProvider: { type: String },
    subscriptionLastPaymentIntentId: { type: Schema.Types.ObjectId, ref: 'PaymentIntent' },
    /** Owner override: shop closed even if "hours" would say open. */
    shopManuallyClosed: { type: Boolean, default: false, index: true },
    /** Short note for staff / optional customer message (e.g. "Mood off", "Stock taking"). */
    shopClosedReason: { type: String, maxlength: 500 },
  },
  { timestamps: true },
);

BusinessSchema.index({ location: '2dsphere' });

export type BusinessDoc = mongoose.InferSchemaType<typeof BusinessSchema>;

export const BusinessModel =
  (mongoose.models.Business as mongoose.Model<BusinessDoc> | undefined) ??
  mongoose.model<BusinessDoc>('Business', BusinessSchema);

