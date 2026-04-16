import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../models/business.dart';
import '../repositories/booking_repository_api.dart';

class AppointmentProvider extends ChangeNotifier {
  final BookingRepositoryApi _repo = BookingRepositoryApi(ApiClient());
  final List<CustomerBooking> _bookings = [];
  List<CustomerBooking> get bookings => List.unmodifiable(_bookings);

  List<CustomerBooking> get upcoming => _bookings
      .where((b) =>
          b.dateTime.isAfter(DateTime.now()) && b.status != 'cancelled')
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<CustomerBooking> get past => _bookings
      .where((b) =>
          b.dateTime.isBefore(DateTime.now()) ||
          b.status == 'cancelled' ||
          b.status == 'completed')
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  List<CustomerBooking> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();

  List<CustomerBooking> get confirmedBookings =>
      _bookings.where((b) => b.status == 'confirmed').toList();

  List<CustomerBooking> get completedBookings =>
      _bookings.where((b) => b.status == 'completed').toList();

  List<CustomerBooking> get cancelledBookings =>
      _bookings.where((b) => b.status == 'cancelled').toList();

  /// Owner dashboard: same [businessTypeId] as [BusinessProvider.selectedBusiness.id]
  /// (e.g. `rentacar`) — not the dummy `businessId` from customer catalog (`rc1`).
  List<CustomerBooking> bookingsForOwnerBusinessType(String businessTypeId) {
    final list =
        _bookings.where((b) => b.businessTypeId == businessTypeId).toList();
    list.sort((a, b) {
      const rank = {
        'pending': 0,
        'confirmed': 1,
        'completed': 2,
        'cancelled': 3,
      };
      final ra = rank[a.status] ?? 9;
      final rb = rank[b.status] ?? 9;
      if (ra != rb) return ra.compareTo(rb);
      return a.dateTime.compareTo(b.dateTime);
    });
    return list;
  }

  void acceptBooking(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i != -1 && _bookings[i].status == 'pending') {
      _bookings[i].status = 'confirmed';
      notifyListeners();
    }
  }

  void rejectBooking(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i != -1 && _bookings[i].status == 'pending') {
      _bookings[i].status = 'cancelled';
      notifyListeners();
    }
  }

  /// Creates a booking via API when `/bookings` is wired; otherwise throws.
  Future<CustomerBooking> createBooking(CustomerBooking booking) async {
    final created = await _repo.createBooking(booking);
    _bookings.insert(0, created);
    notifyListeners();
    return created;
  }

  void cancelBooking(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i != -1) {
      _bookings[i].status = 'cancelled';
      notifyListeners();
    }
  }

  void rescheduleBooking(String id, DateTime newDateTime) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i != -1) {
      _bookings[i] = _bookings[i].copyWith(
        dateTime: newDateTime,
        status: 'pending',
      );
      notifyListeners();
    }
  }
}
