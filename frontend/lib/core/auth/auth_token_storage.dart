import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT pair for API calls ([ApiClient] reads via interceptor).
class AuthTokenStorage {
  AuthTokenStorage._();
  static final AuthTokenStorage instance = AuthTokenStorage._();

  static const String accessKey = 'auth_access_token';
  static const String refreshKey = 'auth_refresh_token';
  static const String userIdKey = 'auth_user_id';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessKey, accessToken);
    await prefs.setString(refreshKey, refreshToken);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(userIdKey, userId);
    }
  }

  Future<void> updateAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessKey, accessToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessKey);
    await prefs.remove(refreshKey);
    await prefs.remove(userIdKey);
  }
}
