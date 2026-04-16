import mongoose, { Schema } from 'mongoose';

const PushTokenSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    token: { type: String, required: true, index: true },
    platform: { type: String, required: true }, // ios|android|web
    app: { type: String, required: true, default: 'bizzway' }, // customer|business|riderServices
    lastSeenAt: { type: Date, required: true, default: () => new Date() },
  },
  { timestamps: true },
);

PushTokenSchema.index({ userId: 1, token: 1 }, { unique: true });

export type PushTokenDoc = mongoose.InferSchemaType<typeof PushTokenSchema>;

export const PushTokenModel =
  (mongoose.models.PushToken as mongoose.Model<PushTokenDoc> | undefined) ??
  mongoose.model<PushTokenDoc>('PushToken', PushTokenSchema);

