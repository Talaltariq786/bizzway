import mongoose, { Schema } from 'mongoose';

const OrderItemSchema = new Schema(
  {
    productId: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
    name: { type: String, required: true },
    qty: { type: Number, required: true, min: 1 },
    unitPrice: { type: Number, required: true, min: 0 },
  },
  { _id: false },
);

const PointSchema = new Schema(
  {
    type: { type: String, enum: ['Point'], required: true, default: 'Point' },
    coordinates: { type: [Number], required: true }, // [lng, lat]
  },
  { _id: false },
);

const OrderSchema = new Schema(
  {
    customerId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    businessId: { type: Schema.Types.ObjectId, ref: 'Business', required: true, index: true },
    items: { type: [OrderItemSchema], required: true },
    subtotal: { type: Number, required: true },
    deliveryFee: { type: Number, default: 0 },
    total: { type: Number, required: true },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'preparing', 'ready', 'picked', 'delivered', 'cancelled'],
      default: 'pending',
      index: true,
    },
    deliveryAddress: { type: String },
    deliveryLocation: { type: PointSchema },
    assignedRiderId: { type: Schema.Types.ObjectId, ref: 'User', index: true },
  },
  { timestamps: true },
);

export type OrderDoc = mongoose.InferSchemaType<typeof OrderSchema>;

export const OrderModel =
  (mongoose.models.Order as mongoose.Model<OrderDoc> | undefined) ??
  mongoose.model<OrderDoc>('Order', OrderSchema);

