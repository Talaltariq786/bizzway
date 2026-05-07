import mongoose, { Schema } from 'mongoose';

const PointSchema = new Schema(
  {
    type: { type: String, enum: ['Point'], required: true, default: 'Point' },
    coordinates: { type: [Number], required: true }, // [lng, lat]
  },
  { _id: false },
);

const ServiceProviderSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    profession: { type: String, required: true, index: true },
    nic: { type: String },
    imageUrl: { type: String },
    planId: { type: String },
    /** Kabari / scrap buyer — material label → rate line shown on Near Me (PKR). */
    scrapRatesDisplay: { type: Map, of: String },
    online: { type: Boolean, default: false, index: true },
    location: { type: PointSchema },
    lastSeenAt: { type: Date },
  },
  { timestamps: true },
);

ServiceProviderSchema.index({ location: '2dsphere' });

export type ServiceProviderDoc = mongoose.InferSchemaType<typeof ServiceProviderSchema>;

export const ServiceProviderModel =
  (mongoose.models.ServiceProvider as mongoose.Model<ServiceProviderDoc> | undefined) ??
  mongoose.model<ServiceProviderDoc>('ServiceProvider', ServiceProviderSchema);

