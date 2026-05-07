import 'api_client.dart';
import 'api_paths.dart';

class NotificationsApi {
  NotificationsApi(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.getJson(ApiPaths.notifications);
    final data = res['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> patch(String id, {required bool isRead}) async {
    await _api.dio.patch<Object?>(
      ApiPaths.notificationById(id),
      data: {'isRead': isRead},
    );
  }

  Future<Map<String, dynamic>> create({
    required String title,
    required String body,
    Map<String, dynamic>? extra,
  }) async {
    final payloadExtra = <String, Object?>{'extra': extra}
      ..removeWhere((_, v) => v == null);
    return _api.postJson(
      ApiPaths.notifications,
      body: {
        'title': title,
        'body': body,
        ...payloadExtra,
      },
    );
  }
}

