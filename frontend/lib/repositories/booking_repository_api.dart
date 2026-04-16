import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/config/offline_mode.dart';
import '../models/business.dart';
import 'booking_repository.dart';

class BookingRepositoryApi implements BookingRepository {
  final ApiClient _api;

  BookingRepositoryApi(this._api);

  @override
  Future<List<CustomerBooking>> listBookings({String? userId}) async {
    if (OfflineMode.enabled) return const [];
    final res = await _api.getJson(
      '/bookings',
      query: userId == null ? null : {'userId': userId},
    );

    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => CustomerBooking.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    throw ApiException('Invalid bookings response shape');
  }

  @override
  Future<CustomerBooking> createBooking(CustomerBooking booking) async {
    if (OfflineMode.enabled) {
      throw ApiException('Offline mode: booking API disabled');
    }
    final res = await _api.postJson('/bookings', body: booking.toJson());
    final data = res['data'];
    if (data is Map) {
      return CustomerBooking.fromJson(data.cast<String, dynamic>());
    }
    throw ApiException('Invalid create booking response shape');
  }
}

