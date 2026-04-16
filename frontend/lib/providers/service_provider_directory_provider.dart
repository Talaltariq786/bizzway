import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/service_provider_profile.dart';

class ServiceProviderDirectoryProvider extends ChangeNotifier {
  static const _kPrefsKey = 'service_provider_directory_v1';
  final List<ServiceProviderProfile> _providers = [];
  bool _loaded = false;

  List<ServiceProviderProfile> get providers => List.unmodifiable(_providers);
  bool get isLoaded => _loaded;

  ServiceProviderDirectoryProvider() {
    Future.microtask(_load);
  }

  void upsert(ServiceProviderProfile profile) {
    final i = _providers.indexWhere((p) => p.id == profile.id);
    if (i == -1) {
      _providers.insert(0, profile);
    } else {
      _providers[i] = profile;
    }
    _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _providers.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _providers
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((m) => ServiceProviderProfile.fromJson(
                        Map<String, dynamic>.from(m),
                      ))
                  .toList(),
            );
        }
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final out = _providers.map((p) => p.toJson()).toList();
      await prefs.setString(_kPrefsKey, jsonEncode(out));
    } catch (_) {}
  }
}

