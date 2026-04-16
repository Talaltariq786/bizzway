class AppConfig {
  AppConfig._();

  /// Example:
  /// - Local:  http://localhost:3000
  /// - Prod:   https://api.yourdomain.com
  ///
  /// NOTE: Android emulator uses http://10.0.2.2:<port> for localhost.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}

