/// Result of picking a point on the map (signup, saved addresses).
class MapLocationResult {
  const MapLocationResult({
    required this.lat,
    required this.lng,
    required this.addressLine,
  });

  final double lat;
  final double lng;

  /// Human-readable line (reverse geocode or fallback).
  final String addressLine;
}
