import 'package:geocoding/geocoding.dart';

/// Formats a [Placemark] for Pakistan-style display; falls back to coordinates.
String formatPlacemarkLine(Placemark p, {required double lat, required double lng}) {
  final raw = <String?>[
    p.street,
    p.subLocality,
    p.locality,
    p.subAdministrativeArea,
    p.administrativeArea,
    p.postalCode,
    p.country,
  ];
  final parts = <String>[];
  for (final s in raw) {
    final t = s?.trim();
    if (t != null && t.isNotEmpty) parts.add(t);
  }
  if (parts.isEmpty) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
  return parts.join(', ');
}
