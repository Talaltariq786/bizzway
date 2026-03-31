import 'package:flutter/material.dart';

// ── Saved address ─────────────────────────────────────────────────────────────

class SavedAddress {
  final String id;
  final String label;   // Home, Office, Other
  final String address;
  final IconData icon;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.icon,
  });

  SavedAddress copyWith({String? label, String? address}) => SavedAddress(
        id: id,
        label: label ?? this.label,
        address: address ?? this.address,
        icon: icon,
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
  final List<SavedAddress> _addresses = [
    const SavedAddress(
      id: 'home',
      label: 'Home',
      address: 'Block 6, PECHS, Karachi',
      icon: Icons.home_rounded,
    ),
    const SavedAddress(
      id: 'office',
      label: 'Office',
      address: 'Clifton, Block 5, Karachi',
      icon: Icons.business_rounded,
    ),
  ];

  String _selectedAddressId = 'home';

  List<SavedAddress> get addresses => List.unmodifiable(_addresses);

  SavedAddress get selectedAddress =>
      _addresses.firstWhere((a) => a.id == _selectedAddressId,
          orElse: () => _addresses.first);

  void selectAddress(String id) {
    _selectedAddressId = id;
    notifyListeners();
  }

  void addAddress(String label, String address, IconData icon) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _addresses.add(SavedAddress(
      id: id,
      label: label,
      address: address,
      icon: icon,
    ));
    notifyListeners();
  }

  void updateAddress(String id, String label, String address) {
    final i = _addresses.indexWhere((a) => a.id == id);
    if (i != -1) {
      _addresses[i] = _addresses[i].copyWith(label: label, address: address);
      notifyListeners();
    }
  }

  void removeAddress(String id) {
    if (_addresses.length <= 1) return;
    _addresses.removeWhere((a) => a.id == id);
    if (_selectedAddressId == id) _selectedAddressId = _addresses.first.id;
    notifyListeners();
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
