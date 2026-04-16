import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Customer-only toggles (push, etc.) persisted locally until backend sync exists.
class CustomerPreferencesProvider extends ChangeNotifier {
  static const _kPushKey = 'customer_push_notifications_enabled';

  bool _pushEnabled = true;

  bool get pushNotificationsEnabled => _pushEnabled;

  CustomerPreferencesProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _pushEnabled = prefs.getBool(_kPushKey) ?? true;
    notifyListeners();
  }

  Future<void> setPushNotifications(bool enabled) async {
    if (_pushEnabled == enabled) return;
    _pushEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPushKey, enabled);
    notifyListeners();
  }
}
