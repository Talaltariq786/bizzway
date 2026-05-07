import 'api_client.dart';
import 'api_paths.dart';

/// Authenticated worker profile (`GET/PUT /api/service-providers/me`).
class ServiceProvidersApi {
  ServiceProvidersApi(this._api);

  final ApiClient _api;

  /// Parsed `provider` object from GET, or null if worker has no row yet.
  Future<Map<String, dynamic>?> getMeProvider() async {
    final res = await _api.getJson(ApiPaths.serviceProvidersMe);
    final p = res['provider'];
    if (p is Map) return Map<String, dynamic>.from(p);
    return null;
  }

  Future<Map<String, dynamic>> putMe({
    required String profession,
    String? nic,
    String? imageUrl,
    String? planId,
    Map<String, String>? scrapRatesDisplay,
  }) async {
    final body = <String, dynamic>{
      'profession': profession,
      if ((nic ?? '').trim().isNotEmpty) 'nic': nic!.trim(),
      if (imageUrl != null && imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl.trim(),
      if (planId != null && planId.trim().isNotEmpty) 'planId': planId.trim(),
    };
    if (scrapRatesDisplay != null) {
      body['scrapRatesDisplay'] = scrapRatesDisplay;
    }
    return _api.putJson(ApiPaths.serviceProvidersMe, body: body);
  }
}
