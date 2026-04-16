import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_paths.dart';
import '../core/config/offline_mode.dart';
import '../models/business.dart';
import '../models/business_type.dart';

/// Customer browse: businesses from `GET /api/businesses` (geo + optional type on server).
class CustomerMarketplaceProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _loading = false;
  String? _error;
  List<Business> _businesses = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Business> get businesses => List.unmodifiable(_businesses);

  /// Loads nearby businesses. Uses Karachi defaults if [nearLat]/[nearLng] null.
  Future<void> refresh({
    double? nearLat,
    double? nearLng,
    double radiusKm = 40,
    String? type,
  }) async {
    if (OfflineMode.enabled) {
      _loading = true;
      _error = null;
      notifyListeners();
      // Offline: just show seeded demo businesses.
      _businesses = allDummyBusinesses;
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    final lat = nearLat ?? 24.8607;
    final lng = nearLng ?? 67.0011;

    try {
      final q = <String, dynamic>{
        'near': '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}',
        'radiusKm': radiusKm.toString(),
      };
      if (type != null && type.isNotEmpty && type != 'all') {
        q['type'] = type;
      }

      final res = await _api.dio.get<List<dynamic>>(
        ApiPaths.businesses,
        queryParameters: q,
      );
      final list = res.data ?? const [];
      _businesses = list.whereType<Map>().map((m) {
        return Business.fromPublicApi(Map<String, dynamic>.from(m));
      }).toList();
      _loading = false;
      notifyListeners();
    } on DioException catch (e) {
      _loading = false;
      _error = ApiClient.messageFromDio(e);
      _businesses = const [];
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      _businesses = const [];
      notifyListeners();
    }
  }

  List<Business> filtered({
    required String effectiveBrowseTypeId,
    required String searchQuery,
  }) {
    final allowedTypeIds =
        BusinessType.customerBrowseTypes.map((t) => t.id).toSet();
    var list = _businesses
        .where((b) => allowedTypeIds.contains(b.businessTypeId))
        .toList();
    if (effectiveBrowseTypeId != 'all') {
      list =
          list.where((b) => b.businessTypeId == effectiveBrowseTypeId).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (b) =>
                b.name.toLowerCase().contains(q) ||
                b.address.toLowerCase().contains(q) ||
                b.businessTypeId.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }
}
