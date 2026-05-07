import 'api_client.dart';
import 'api_paths.dart';

class PushApi {
  PushApi(this._api);
  final ApiClient _api;

  Future<void> saveToken(String token, {String platform = 'unknown'}) async {
    await _api.postJson(
      ApiPaths.pushTokens,
      body: {
        'token': token,
        'platform': platform,
      },
    );
  }

  Future<void> deleteToken(String token) async {
    await _api.dio.delete<Object?>(
      ApiPaths.pushTokens,
      data: {'token': token},
    );
  }

  Future<void> sendTest({required String token, String? title, String? body}) async {
    final extra = <String, Object?>{
      'title': title,
      'body': body,
    }..removeWhere((_, v) => v == null);
    await _api.postJson(
      ApiPaths.pushTest,
      body: {
        'token': token,
        ...extra,
      },
    );
  }
}

