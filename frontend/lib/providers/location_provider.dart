import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only const [Icons.*] — required for release `tree-shake-icons` (no dynamic IconData).
IconData savedAddressIconFromCodePoint(int codePoint) {
  if (codePoint == Icons.home_rounded.codePoint) return Icons.home_rounded;
  if (codePoint == Icons.work_rounded.codePoint) return Icons.work_rounded;
  if (codePoint == Icons.work_outline_rounded.codePoint) {
    return Icons.work_outline_rounded;
  }
  if (codePoint == Icons.business_rounded.codePoint) return Icons.business_rounded;
  if (codePoint == Icons.location_on_rounded.codePoint) {
    return Icons.location_on_rounded;
  }
  if (codePoint == Icons.location_city_rounded.codePoint) {
    return Icons.location_city_rounded;
  }
  if (codePoint == Icons.local_shipping_rounded.codePoint) {
    return Icons.local_shipping_rounded;
  }
  if (codePoint == Icons.person_pin_rounded.codePoint) {
    return Icons.person_pin_rounded;
  }
  if (codePoint == Icons.other_houses_rounded.codePoint) {
    return Icons.other_houses_rounded;
  }
  return Icons.location_on_rounded;
}

// ── Saved address ─────────────────────────────────────────────────────────────

class SavedAddress {
  final String id;
  final String label;   // Home, Office, Other
  final String address;
  final IconData icon;
  final double? lat;
  final double? lng;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.icon,
    this.lat,
    this.lng,
  });

  SavedAddress copyWith({String? label, String? address, double? lat, double? lng}) =>
      SavedAddress(
        id: id,
        label: label ?? this.label,
        address: address ?? this.address,
        icon: icon,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}

// ── Prayer time ───────────────────────────────────────────────────────────────

class PrayerTime {
  final String name;
  final String nameUrdu;
  final TimeOfDay time;
  final IconData icon;

  const PrayerTime({
    required this.name,
    required this.nameUrdu,
    required this.time,
    required this.icon,
  });
}

// ── LocationProvider ──────────────────────────────────────────────────────────

class LocationProvider extends ChangeNotifier {
  // ── Delivery addresses ────────────────────────────────────────────────────
  static const _kPrefsKeyAddresses = 'saved_addresses_v1';
  static const _kPrefsKeySelected = 'saved_addresses_selected_v1';

  final List<SavedAddress> _addresses = [];

  String _selectedAddressId = 'home';

  List<SavedAddress> get addresses => List.unmodifiable(_addresses);

  SavedAddress get selectedAddress => _addresses.firstWhere(
        (a) => a.id == _selectedAddressId,
        orElse: () => _addresses.isEmpty ? _fallbackAddress() : _addresses.first,
      );

  LocationProvider() {
    Future.microtask(_load);
  }

  void selectAddress(String id) {
    _selectedAddressId = id;
    _persistSelected();
    notifyListeners();
  }

  /// Adds a saved address; [lat]/[lng] drive nearby shops when set.
  String addAddress(
    String label,
    String address,
    IconData icon, {
    double? lat,
    double? lng,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _addresses.add(SavedAddress(
      id: id,
      label: label,
      address: address,
      icon: icon,
      lat: lat,
      lng: lng,
    ));
    _selectedAddressId = id;
    _persistAll();
    _persistSelected();
    notifyListeners();
    return id;
  }

  void updateAddress(
    String id,
    String label,
    String address, {
    double? lat,
    double? lng,
  }) {
    final i = _addresses.indexWhere((a) => a.id == id);
    if (i != -1) {
      _addresses[i] = _addresses[i].copyWith(
        label: label,
        address: address,
        lat: lat,
        lng: lng,
      );
      _persistAll();
      notifyListeners();
    }
  }

  void removeAddress(String id) {
    if (_addresses.length <= 1) return;
    _addresses.removeWhere((a) => a.id == id);
    if (_selectedAddressId == id) _selectedAddressId = _addresses.first.id;
    _persistAll();
    _persistSelected();
    notifyListeners();
  }

  SavedAddress _fallbackAddress() => const SavedAddress(
        id: 'home',
        label: 'Home',
        address: 'Karachi (map se pin karein)',
        icon: Icons.home_rounded,
        lat: 24.8607,
        lng: 67.0011,
      );

  /// After customer signup: one home row with real coords for `/api/businesses?near=`.
  Future<void> applyCustomerSignupAddress({
    required String address,
    double? lat,
    double? lng,
  }) async {
    final trimmed = address.trim();
    var la = lat;
    var ln = lng;
    if (la == null || ln == null) {
      if (trimmed.length >= 4) {
        try {
          final found = await locationFromAddress('$trimmed, Pakistan');
          if (found.isNotEmpty) {
            la = found.first.latitude;
            ln = found.first.longitude;
          }
        } catch (_) {}
      }
    }
    la ??= 24.8607;
    ln ??= 67.0011;
    _addresses
      ..clear()
      ..add(
        SavedAddress(
          id: 'home',
          label: 'Home',
          address: trimmed.isEmpty ? 'Pakistan' : trimmed,
          icon: Icons.home_rounded,
          lat: la,
          lng: ln,
        ),
      );
    _selectedAddressId = 'home';
    await _persistAll();
    await _persistSelected();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKeyAddresses);
    final selected = prefs.getString(_kPrefsKeySelected);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _addresses
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map((m) {
                final mm = Map<String, dynamic>.from(m);
                return SavedAddress(
                  id: (mm['id'] ?? '').toString(),
                  label: (mm['label'] ?? '').toString(),
                  address: (mm['address'] ?? '').toString(),
                  icon: savedAddressIconFromCodePoint(
                    (mm['iconCodePoint'] as num?)?.toInt() ??
                        Icons.location_on_rounded.codePoint,
                  ),
                  lat: (mm['lat'] as num?)?.toDouble(),
                  lng: (mm['lng'] as num?)?.toDouble(),
                );
              }),
            );
        }
      } catch (_) {}
    }

    if (_addresses.isEmpty) {
      _addresses.add(_fallbackAddress());
    }

    if (selected != null &&
        selected.isNotEmpty &&
        _addresses.any((a) => a.id == selected)) {
      _selectedAddressId = selected;
    } else {
      _selectedAddressId = _addresses.first.id;
    }
    notifyListeners();
  }

  Future<void> _persistSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefsKeySelected, _selectedAddressId);
    } catch (_) {}
  }

  Future<void> _persistAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final out = _addresses
          .map(
            (a) => {
              'id': a.id,
              'label': a.label,
              'address': a.address,
              'iconCodePoint': a.icon.codePoint,
              'lat': a.lat,
              'lng': a.lng,
            },
          )
          .toList();
      await prefs.setString(_kPrefsKeyAddresses, jsonEncode(out));
    } catch (_) {}
  }

  // ── Prayer times (Karachi) ────────────────────────────────────────────────
  final List<PrayerTime> prayerTimes = const [
    PrayerTime(
      name: 'Fajr',
      nameUrdu: 'فجر',
      time: TimeOfDay(hour: 5, minute: 15),
      icon: Icons.wb_twilight_rounded,
    ),
    PrayerTime(
      name: 'Dhuhr',
      nameUrdu: 'ظہر',
      time: TimeOfDay(hour: 12, minute: 30),
      icon: Icons.wb_sunny_rounded,
    ),
    PrayerTime(
      name: 'Asr',
      nameUrdu: 'عصر',
      time: TimeOfDay(hour: 16, minute: 0),
      icon: Icons.wb_cloudy_rounded,
    ),
    PrayerTime(
      name: 'Maghrib',
      nameUrdu: 'مغرب',
      time: TimeOfDay(hour: 18, minute: 45),
      icon: Icons.nights_stay_outlined,
    ),
    PrayerTime(
      name: 'Isha',
      nameUrdu: 'عشاء',
      time: TimeOfDay(hour: 20, minute: 0),
      icon: Icons.nightlight_round,
    ),
  ];

  /// Next upcoming prayer based on current time
  PrayerTime get nextPrayer {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    for (final p in prayerTimes) {
      final pMinutes = p.time.hour * 60 + p.time.minute;
      if (pMinutes > nowMinutes) return p;
    }
    return prayerTimes.first; // after Isha, next is Fajr
  }

  /// Minutes until next prayer
  int get minutesUntilNextPrayer {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final next = nextPrayer;
    var nextMinutes = next.time.hour * 60 + next.time.minute;
    if (nextMinutes <= nowMinutes) nextMinutes += 24 * 60; // next day
    return nextMinutes - nowMinutes;
  }

  String get nextPrayerCountdown {
    final mins = minutesUntilNextPrayer;
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String formatPrayerTime(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
