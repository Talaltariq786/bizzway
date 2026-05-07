import 'service_provider_profile.dart';

/// Maps `GET /api/service-providers` JSON entries to [ServiceProviderProfile].
class ServiceProviderProfileMapper {
  ServiceProviderProfileMapper._();

  static Map<String, String> _scrap(Map<String, dynamic> json) {
    final raw = json['scrapRatesDisplay'];
    if (raw is! Map) return {};
    return Map<String, String>.from(
      raw.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  static ServiceProviderProfile fromSearchApi(Map<String, dynamic> json) {
    final phone = (json['phone'] ?? '').toString().trim();
    final userId = (json['userId'] ?? '').toString().trim();
    final fallbackId = (json['id'] ?? '').toString().trim();
    final id =
        phone.isNotEmpty ? phone : (userId.isNotEmpty ? userId : fallbackId);

    double? lat = (json['lat'] as num?)?.toDouble();
    double? lng = (json['lng'] as num?)?.toDouble();
    final loc = json['location'];
    if ((lat == null || lng == null) && loc is Map && loc['coordinates'] is List) {
      final c = loc['coordinates'] as List<dynamic>;
      if (c.length >= 2) {
        lng ??= (c[0] as num?)?.toDouble();
        lat ??= (c[1] as num?)?.toDouble();
      }
    }

    final lastSeen = DateTime.tryParse((json['lastSeenAt'] ?? '').toString());
    final rawName = (json['name'] ?? 'Service Provider').toString().trim();
    final name = rawName.isEmpty ? 'Service Provider' : rawName;

    return ServiceProviderProfile(
      id: id.isNotEmpty ? id : fallbackId,
      name: name,
      phone: phone.isNotEmpty ? phone : '—',
      profession: (json['profession'] ?? '').toString(),
      nic: json['nic']?.toString(),
      imagePath: json['imageUrl']?.toString(),
      plan: json['planId']?.toString(),
      isOnline: json['online'] == true,
      areaLabel: 'Near you',
      lat: lat,
      lng: lng,
      updatedAt: lastSeen,
      createdAt: lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0),
      scrapRatesDisplay: _scrap(json),
    );
  }
}
