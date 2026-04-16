import mongoose, { Schema } from 'mongoose';

const ChatSchema = new Schema(
  {
    participants: { type: [Schema.Types.ObjectId], ref: 'User', required: true, index: true },
    type: { type: String, enum: ['customer_owner', 'customer_rider'], required: true, index: true },
    lastMessageAt: { type: Date },
  },
  { timestamps: true },
);

ChatSchema.index({ participants: 1, type: 1 });

export type ChatDoc = mongoose.InferSchemaType<typeof ChatSchema>;

export const ChatModel =
  (mongoose.models.Chat as mongoose.Model<ChatDoc> | undefined) ??
  mongoose.model<ChatDoc>('Chat', ChatSchema);

