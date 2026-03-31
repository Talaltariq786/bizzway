import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../models/business.dart';
import '../repositories/booking_repository_api.dart';

class AppointmentProvider extends ChangeNotifier {
  final BookingRepositoryApi _repo = BookingRepositoryApi(ApiClient());

  final List<CustomerBooking> _bookings = [
    // ── Demo bookings with different statuses ─────────────────────────────
    CustomerBooking(
      id: 'BK-001',
      businessId: 'salon1',
      businessName: 'Glamour Studio',
      businessTypeId: 'salon',
      itemId: 'haircut',
      itemName: 'Haircut & Style',
      price: 800,
      durationMinutes: 45,
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      status: 'pending',
      notes: 'Short cut please',
    ),
    CustomerBooking(
      id: 'BK-002',
      businessId: 'gym1',
      businessName: 'FitZone Gym',
      businessTypeId: 'gym',
      itemId: 'pt',
      itemName: 'Personal Training Session',
      price: 1500,
      durationMinutes: 60,
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
      status: 'confirmed',
    ),
    CustomerBooking(
      id: 'BK-003',
      businessId: 'clinic1',
      businessName: 'City Clinic',
      businessTypeId: 'clinic',
      itemId: 'consult',
      itemName: 'General Consultation',
      price: 1200,
      durationMinutes: 30,
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      status: 'completed',
    ),
    CustomerBooking(
      id: 'BK-004',
      businessId: 'beauty1',
      businessName: 'Pearl Beauty Parlor',
      businessTypeId: 'beauty',
      itemId: 'facial',
      itemName: 'Deep Cleansing Facial',
      price: 2200,
      durationMinutes: 75,
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      status: 'cancelled',
    ),
    CustomerBooking(
      id: 'BK-005',
      businessId: 'salon1',
      businessName: 'Glamour Studio',
      businessTypeId: 'salon',
      itemId: 'spa',
      itemName: 'Full Body Massage',
      price: 3500,
      durationMinutes: 90,
      dateTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
      status: 'pending',
    ),
  ];

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

  /// Creates a booking via API (if backend available) and updates local list.
  /// If API fails, we still insert locally so demo keeps working.
  Future<CustomerBooking> createBooking(CustomerBooking booking) async {
    try {
      final created = await _repo.createBooking(booking);
      _bookings.insert(0, created);
      notifyListeners();
      return created;
    } catch (_) {
      _bookings.insert(0, booking);
      notifyListeners();
      return booking;
    }
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
      _bookings[i] = CustomerBooking(
        id: _bookings[i].id,
        businessId: _bookings[i].businessId,
        businessName: _bookings[i].businessName,
        businessTypeId: _bookings[i].businessTypeId,
        itemId: _bookings[i].itemId,
        itemName: _bookings[i].itemName,
        price: _bookings[i].price,
        durationMinutes: _bookings[i].durationMinutes,
        dateTime: newDateTime,
        status: 'pending', // reset to pending after reschedule
        notes: _bookings[i].notes,
      );
      notifyListeners();
    }
  }
}
