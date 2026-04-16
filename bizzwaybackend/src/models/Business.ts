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
  },
  { timestamps: true },
);

BusinessSchema.index({ location: '2dsphere' });

export type BusinessDoc = mongoose.InferSchemaType<typeof BusinessSchema>;

export const BusinessModel =
  (mongoose.models.Business as mongoose.Model<BusinessDoc> | undefined) ??
  mongoose.model<BusinessDoc>('Business', BusinessSchema);

