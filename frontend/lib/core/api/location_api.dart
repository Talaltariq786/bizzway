import 'api_client.dart';
import 'api_paths.dart';

class LocationApi {
  LocationApi(this._api);
  final ApiClient _api;

  Future<void> postServiceProviderLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) async {
    final extra = <String, Object?>{
      'heading': heading,
      'speed': speed,
    }..removeWhere((_, v) => v == null);
    await _api.postJson(
      ApiPaths.serviceProvidersMeLocation,
      body: {
        'lat': lat,
        'lng': lng,
        ...extra,
      },
    );
  }

  Future<void> postRiderLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) async {
    final extra = <String, Object?>{
      'heading': heading,
      'speed': speed,
    }..removeWhere((_, v) => v == null);
    await _api.postJson(
      ApiPaths.ridersMeLocation,
      body: {
        'lat': lat,
        'lng': lng,
        ...extra,
      },
    );
  }

  Future<List<Map<String, dynamic>>> searchServiceProviders({
    required double nearLat,
    required double nearLng,
    double radiusKm = 5,
    String? profession,
  }) async {
    final res = await _api.dio.get<List<dynamic>>(
      ApiPaths.serviceProvidersSearch,
      queryParameters: {
        'near': '${nearLat.toStringAsFixed(5)},${nearLng.toStringAsFixed(5)}',
        'radiusKm': radiusKm.toString(),
        if (profession != null && profession.isNotEmpty) 'profession': profession,
      },
    );
    return (res.data ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}

