/// Business owner khud rider add karta hai — [riderId] unique hoti hai per store.
class OwnedRider {
  final String riderId;
  final String name;
  final String phone;
  final DateTime createdAt;

  const OwnedRider({
    required this.riderId,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'name': name,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OwnedRider.fromJson(Map<String, dynamic> m) {
    return OwnedRider(
      riderId: m['riderId'] as String,
      name: m['name'] as String,
      phone: m['phone'] as String,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

