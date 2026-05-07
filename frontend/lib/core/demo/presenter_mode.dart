import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps demo features "cleanly separated" from production UX.
///
/// - In debug: can be enabled/disabled from UI.
/// - In release: default OFF (unless you ship a custom build flag later).
class PresenterMode {
  PresenterMode._();

  static const _kPrefsKey = 'presenter_mode_enabled_v1';

  static bool _loaded = false;
  static bool enabled = false;

  /// Call once on startup.
  static Future<void> initFromPrefs() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      enabled = p.getBool(_kPrefsKey) ?? false;
    } catch (_) {
      enabled = false;
    }
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kPrefsKey, v);
    } catch (_) {}
    if (kDebugMode) debugPrint('PresenterMode.enabled=$enabled');
  }
}

