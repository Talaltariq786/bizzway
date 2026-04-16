import mongoose, { Schema } from 'mongoose';
import type { Role } from '../types/auth.js';

const AddressSchema = new Schema(
  {
    id: { type: String, required: true }, // client-generated id
    label: { type: String, required: true }, // Home|Office|Other
    address: { type: String, required: true },
    lat: { type: Number, required: false },
    lng: { type: Number, required: false },
    isSelected: { type: Boolean, required: true, default: false },
  },
  { _id: false },
);

const UserSchema = new Schema(
  {
    phone: { type: String, index: true, unique: true, sparse: true },
    email: { type: String, index: true, unique: true, sparse: true },
    passwordHash: { type: String, required: true, select: false },
    roles: { type: [String], required: true, default: ['customer'] },
    name: { type: String },
    avatarUrl: { type: String },
    addresses: { type: [AddressSchema], required: true, default: [] },
  },
  { timestamps: true },
);

export type UserDoc = mongoose.InferSchemaType<typeof UserSchema> & {
  roles: Role[];
};

export const UserModel =
  (mongoose.models.User as mongoose.Model<UserDoc> | undefined) ??
  mongoose.model<UserDoc>('User', UserSchema);

