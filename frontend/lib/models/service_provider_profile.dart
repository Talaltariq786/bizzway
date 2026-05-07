import 'package:flutter/material.dart';

class ServiceProviderProfile {
  final String id; // stable id (phone)
  final String name;
  final String phone;
  final String profession;
  final String? nic;
  final String? imagePath;
  final String? plan;
  final bool isOnline;
  final String areaLabel;
  final double? lat;
  final double? lng;
  final DateTime? updatedAt;
  final DateTime createdAt;

  /// Material → rate line (e.g. "Plastic" → "Rs 85 / kg") for kabari / scrap buyers.
  final Map<String, String> scrapRatesDisplay;

  const ServiceProviderProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.profession,
    this.nic,
    this.imagePath,
    this.plan,
    this.isOnline = true,
    this.areaLabel = 'Near you',
    this.lat,
    this.lng,
    this.updatedAt,
    required this.createdAt,
    this.scrapRatesDisplay = const {},
  });

  IconData get icon {
    final p = profession.toLowerCase();
    if (p.contains('electric')) return Icons.electrical_services_rounded;
    if (p.contains('plumb')) return Icons.plumbing_rounded;
    if (p.contains('carp')) return Icons.carpenter_rounded;
    if (p.contains('paint')) return Icons.format_paint_rounded;
    if (p.contains('mechanic') || p.contains('auto')) return Icons.build_rounded;
    if (p.contains('ac')) return Icons.ac_unit_rounded;
    if (p.contains('kabari') ||
        p.contains('scrap') ||
        p.contains('kabad') ||
        p.contains('kabadi')) {
      return Icons.recycling_rounded;
    }
    return Icons.handyman_rounded;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'profession': profession,
        'nic': nic,
        'imagePath': imagePath,
        'plan': plan,
        'isOnline': isOnline,
        'areaLabel': areaLabel,
        'lat': lat,
        'lng': lng,
        'updatedAt': updatedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'scrapRatesDisplay': scrapRatesDisplay,
      };

  factory ServiceProviderProfile.fromJson(Map<String, dynamic> json) {
    return ServiceProviderProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      profession: (json['profession'] ?? '').toString(),
      nic: json['nic']?.toString(),
      imagePath: json['imagePath']?.toString(),
      plan: json['plan']?.toString(),
      isOnline: (json['isOnline'] as bool?) ?? true,
      areaLabel: (json['areaLabel'] ?? 'Near you').toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      scrapRatesDisplay: () {
        final m = json['scrapRatesDisplay'];
        if (m is Map) {
          return Map<String, String>.from(
            m.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
        return <String, String>{};
      }(),
    );
  }
}

