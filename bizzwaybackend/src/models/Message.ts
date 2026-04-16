import mongoose, { Schema } from 'mongoose';

const MessageSchema = new Schema(
  {
    chatId: { type: Schema.Types.ObjectId, ref: 'Chat', required: true, index: true },
    senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    text: { type: String, required: true },
    readBy: { type: [Schema.Types.ObjectId], ref: 'User', default: [] },
  },
  { timestamps: true },
);

export type MessageDoc = mongoose.InferSchemaType<typeof MessageSchema>;

export const MessageModel =
  (mongoose.models.Message as mongoose.Model<MessageDoc> | undefined) ??
  mongoose.model<MessageDoc>('Message', MessageSchema);

