/// When **true**, the app skips the backend (dummy login, sample listings, etc.).
///
/// - **Default is `true`** — no Mongo/Node required; app runs standalone.
/// - Jab backend integrate karna ho: `flutter run --dart-define=OFFLINE_MODE=false`
///   (saath `API_BASE_URL` ya login **API:** row).
class OfflineMode {
  static const bool enabled = bool.fromEnvironment(
    'OFFLINE_MODE',
    defaultValue: false,
  );
}
