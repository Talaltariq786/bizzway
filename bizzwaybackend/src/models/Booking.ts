import mongoose, { Schema } from 'mongoose';

const BookingSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    businessId: { type: Schema.Types.ObjectId, ref: 'Business', required: true, index: true },
    businessType: { type: String, required: true },
    businessName: { type: String, required: true },

    itemId: { type: String, required: true },
    itemName: { type: String, required: true },
    price: { type: Number, required: true },
    durationMinutes: { type: Number, required: false },

    dateTime: { type: Date, required: true, index: true },
    status: { type: String, required: true, default: 'pending' }, // pending|confirmed|completed|cancelled
    notes: { type: String, required: false },

    // Optional: rent-a-car / special flows
    customerFullName: { type: String, required: false },
    customerNic: { type: String, required: false },
    customerLicenseNo: { type: String, required: false },
    bookingCode: { type: String, required: false },
    vehicleHandoverMode: { type: String, required: false },
    rentacarTripType: { type: String, required: false },
    pickupAddress: { type: String, required: false },
    dropoffAddress: { type: String, required: false },
  },
  { timestamps: true },
);

export type BookingDoc = mongoose.InferSchemaType<typeof BookingSchema>;

export const BookingModel =
  (mongoose.models.Booking as mongoose.Model<BookingDoc> | undefined) ??
  mongoose.model<BookingDoc>('Booking', BookingSchema);

