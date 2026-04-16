import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';

/// Theme mode (system / light / dark) + app-wide accent color (customer-style), persisted.
class ThemeProvider extends ChangeNotifier {
  static const _kThemeModeKey = 'theme_mode'; // 0=system, 1=light, 2=dark
  static const _kAccentKey = 'customer_accent_color';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Primary accent for [AppTheme.lightThemeWithAccent] / dark variant (buttons, nav, customer gradients).
  Color _accentColor = AppColors.primary;
  Color get accentColor => _accentColor;

  ThemeProvider() {
    _load();
  }

  bool get isDark => _mode == ThemeMode.dark;

  /// After async work, defer [notifyListeners] so we never rebuild during a
  /// bad scheduler phase (e.g. overlapping [MaterialApp] / route updates).
  void _notifyListenersDeferred() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_kThemeModeKey) ?? 0;
    final next = switch (raw) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final accentInt = prefs.getInt(_kAccentKey);
    if (accentInt != null) {
      _accentColor = Color(accentInt);
    }
    if (next == _mode) {
      notifyListeners();
      return;
    }
    _mode = next;
    _notifyListenersDeferred();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
      ThemeMode.system => 0,
    };
    await prefs.setInt(_kThemeModeKey, raw);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await setMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAccentKey, color.toARGB32());
    notifyListeners();
  }
}

