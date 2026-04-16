import mongoose, { Schema } from 'mongoose';

const PointSchema = new Schema(
  {
    type: { type: String, enum: ['Point'], required: true, default: 'Point' },
    coordinates: { type: [Number], required: true }, // [lng, lat]
  },
  { _id: false },
);

const RiderSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    businessId: { type: Schema.Types.ObjectId, ref: 'Business', index: true },
    // Profile fields (for rider app)
    licenseNo: { type: String },
    nic: { type: String },
    bikeNumber: { type: String },
    walletAmount: { type: Number, default: 0 },
    planId: { type: String },
    online: { type: Boolean, default: false, index: true },
    location: { type: PointSchema },
    lastSeenAt: { type: Date },
  },
  { timestamps: true },
);

RiderSchema.index({ location: '2dsphere' });

export type RiderDoc = mongoose.InferSchemaType<typeof RiderSchema>;

export const RiderModel =
  (mongoose.models.Rider as mongoose.Model<RiderDoc> | undefined) ??
  mongoose.model<RiderDoc>('Rider', RiderSchema);

