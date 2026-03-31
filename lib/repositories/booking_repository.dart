import '../models/business.dart';

abstract class BookingRepository {
  Future<List<CustomerBooking>> listBookings({String? userId});
  Future<CustomerBooking> createBooking(CustomerBooking booking);
}

