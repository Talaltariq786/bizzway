import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Customer display name on device (SharedPreferences).
class CustomerProfileNotifier extends ChangeNotifier {
  static const _prefsKey = 'customer_display_name';

  String _displayName = '';
  bool _loaded = false;

  bool get isLoaded => _loaded;
  String get displayName => _displayName;

  /// Loads from prefs once; safe to call multiple times.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString(_prefsKey) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, trimmed);
    _displayName = trimmed;
    notifyListeners();
  }
}

