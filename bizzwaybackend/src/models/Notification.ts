import mongoose, { Schema } from 'mongoose';

const NotificationSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true },
    body: { type: String, required: true },
    kind: { type: String, required: true, default: 'info' }, // info|success|warning|error
    isRead: { type: Boolean, required: true, default: false },
    data: { type: Schema.Types.Mixed, required: false },
  },
  { timestamps: true },
);

export type NotificationDoc = mongoose.InferSchemaType<typeof NotificationSchema>;

export const NotificationModel =
  (mongoose.models.Notification as mongoose.Model<NotificationDoc> | undefined) ??
  mongoose.model<NotificationDoc>('Notification', NotificationSchema);

