import mongoose, { Schema } from 'mongoose';

const ProductSchema = new Schema(
  {
    businessId: { type: Schema.Types.ObjectId, ref: 'Business', required: true, index: true },
    name: { type: String, required: true, index: true },
    /** App / owner category label (matches BusinessType.categories in Flutter). */
    category: { type: String, default: 'General', index: true },
    price: { type: Number, required: true },
    images: { type: [String], default: [] },
    stock: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true, index: true },
  },
  { timestamps: true },
);

export type ProductDoc = mongoose.InferSchemaType<typeof ProductSchema>;

export const ProductModel =
  (mongoose.models.Product as mongoose.Model<ProductDoc> | undefined) ??
  mongoose.model<ProductDoc>('Product', ProductSchema);

