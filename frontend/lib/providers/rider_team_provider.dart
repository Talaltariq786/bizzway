import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/owned_rider.dart';

/// Har [businessId] ke liye alag rider list — owner khud ID banata hai.
class RiderTeamProvider extends ChangeNotifier {
  static const _kPrefsKey = 'owned_riders_by_business_v1';

  final Map<String, List<OwnedRider>> _byBusiness = {};
  bool _loaded = false;

  RiderTeamProvider() {
    Future.microtask(_load);
  }

  bool get isLoaded => _loaded;

  /// Same device par owner ne jo riders add kiye — login match ke liye.
  static String normalizePhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  /// Owner app ne jo ID + phone diya ho — rider app login.
  ({String businessId, OwnedRider rider})? findTeamRiderForLogin(
    String riderId,
    String phone,
  ) {
    final id = riderId.trim().toLowerCase();
    final p = normalizePhone(phone);
    if (id.isEmpty || p.length < 10) return null;
    for (final e in _byBusiness.entries) {
      for (final r in e.value) {
        if (r.riderId.toLowerCase() == id && normalizePhone(r.phone) == p) {
          return (businessId: e.key, rider: r);
        }
      }
    }
    return null;
  }

  Future<void> ensureLoaded() async {
    var n = 0;
    while (!_loaded && n < 150) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      n++;
    }
  }

  List<OwnedRider> ridersFor(String businessId) {
    if (businessId.isEmpty) return const [];
    return List.unmodifiable(_byBusiness[businessId] ?? const []);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _byBusiness.clear();
        map.forEach((key, value) {
          if (value is List) {
            _byBusiness[key] = value
                .map(
                  (e) =>
                      OwnedRider.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList();
          }
        });
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, dynamic>{};
    _byBusiness.forEach((k, v) {
      out[k] = v.map((r) => r.toJson()).toList();
    });
    await prefs.setString(_kPrefsKey, jsonEncode(out));
  }

  /// Returns error message or null if OK.
  Future<String?> addRider({
    required String businessId,
    required String riderId,
    required String name,
    required String phone,
  }) async {
    final id = riderId.trim();
    final n = name.trim();
    final p = phone.trim();
    if (businessId.isEmpty) return 'Business select karein.';
    if (id.isEmpty) return 'Rider ID zaroori hai.';
    if (n.isEmpty) return 'Naam zaroori hai.';
    if (p.isEmpty) return 'Phone zaroori hai.';
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      return 'ID sirf letters, numbers, - ya _ ho sakte hain.';
    }
    final list = _byBusiness.putIfAbsent(businessId, () => []);
    if (list.any((r) => r.riderId.toLowerCase() == id.toLowerCase())) {
      return 'Yeh ID pehle se maujood hai.';
    }
    list.add(
      OwnedRider(riderId: id, name: n, phone: p, createdAt: DateTime.now()),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> removeRider(String businessId, String riderId) async {
    final list = _byBusiness[businessId];
    if (list == null) return;
    list.removeWhere((r) => r.riderId == riderId);
    if (list.isEmpty) _byBusiness.remove(businessId);
    await _persist();
    notifyListeners();
  }
}

