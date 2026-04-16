/// When **true**, the app skips the backend (dummy login, sample listings, etc.).
///
/// - **Default is `true`** — no REST calls, so the app works when the server is off.
/// - Real device/API integration: run with
///   `flutter run --dart-define=OFFLINE_MODE=false`
///   (Mongo + `npm run dev` must be up, or you will see connection errors.)
class OfflineMode {
  static const bool enabled = bool.fromEnvironment(
    'OFFLINE_MODE',
    defaultValue: true,
  );
}
