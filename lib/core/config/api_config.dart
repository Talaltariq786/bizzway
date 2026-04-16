import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend base URL used by [ApiClient].
///
/// Priority: `API_BASE_URL` (dart-define) → saved **dev URL** (in-app) →
/// `API_DEV_HOST` → platform default.
///
/// **Simulator:** iOS/macOS → `127.0.0.1:8080`. **Android emulator** → `10.0.2.2:8080`.
///
/// **Physical phone:** defaults do **not** reach your dev machine (`127.0.0.1` / `10.0.2.2`
/// point to the device/emulator bridge). Set LAN URL via login **“API:”** row or
/// `--dart-define=API_BASE_URL=http://<Mac-IP>:8080`.
class ApiConfig {
  static const _kPrefsDevBase = 'dev_api_base_url';

  static String? _prefsOverride;
  static bool _iosPhysicalDevice = false;
  static bool _androidPhysicalDevice = false;

  /// Call from [main] before [runApp] so the first [ApiClient] uses the right host.
  static Future<void> initFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_kPrefsDevBase)?.trim();
      _prefsOverride = (s != null && s.isNotEmpty) ? s : null;
    } catch (_) {
      _prefsOverride = null;
    }

    try {
      if (Platform.isIOS) {
        final ios = await DeviceInfoPlugin().iosInfo;
        _iosPhysicalDevice = ios.isPhysicalDevice;
      } else if (Platform.isAndroid) {
        final a = await DeviceInfoPlugin().androidInfo;
        _androidPhysicalDevice = a.isPhysicalDevice;
      }
    } catch (_) {
      _iosPhysicalDevice = false;
      _androidPhysicalDevice = false;
    }
  }

  /// Real device + no custom URL/env — user must set Mac/PC LAN IP (also shows API row in release).
  static bool get shouldPromptForLanHost {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return false;
    if (_prefsOverride != null && _prefsOverride!.isNotEmpty) return false;
    const devHost = String.fromEnvironment('API_DEV_HOST', defaultValue: '');
    if (devHost.isNotEmpty) return false;
    if (Platform.isIOS && _iosPhysicalDevice) return true;
    if (Platform.isAndroid && _androidPhysicalDevice) return true;
    return false;
  }

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return _normalizeBase(fromEnv);
    if (_prefsOverride != null && _prefsOverride!.isNotEmpty) {
      return _normalizeBase(_prefsOverride!);
    }
    return _defaultBaseUrl();
  }

  /// Saved override (after [initFromPrefs]); empty if none.
  static String get devBaseUrlDisplay {
    if (_prefsOverride != null && _prefsOverride!.isNotEmpty) {
      return _normalizeBase(_prefsOverride!);
    }
    return '';
  }

  /// Persists full base URL, e.g. `http://192.168.1.10:8080`.
  /// Caller must call [ApiClient.resetShared] after this so the next request uses the new host.
  static Future<void> setDevBaseUrl(String raw) async {
    final t = raw.trim();
    if (t.isEmpty) {
      await clearDevBaseUrl();
      return;
    }
    if (!t.startsWith('http://') && !t.startsWith('https://')) {
      throw ArgumentError('URL http:// ya https:// se shuru hona chahiye');
    }
    final normalized = _normalizeBase(t);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrefsDevBase, normalized);
    _prefsOverride = normalized;
  }

  static Future<void> clearDevBaseUrl() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kPrefsDevBase);
    } catch (_) {}
    _prefsOverride = null;
  }

  static String _normalizeBase(String u) {
    var s = u.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static String _defaultBaseUrl() {
    const devHost = String.fromEnvironment('API_DEV_HOST', defaultValue: '');
    if (devHost.isNotEmpty) {
      return 'http://$devHost:8080';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://127.0.0.1:8080';
  }
}

