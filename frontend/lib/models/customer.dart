class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  int totalOrders;
  double totalSpent;
  DateTime lastVisit;
  final DateTime joinedAt;
  final String imageUrl;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.totalOrders = 0,
    this.totalSpent = 0,
    DateTime? lastVisit,
    DateTime? joinedAt,
    this.imageUrl = 'https://via.placeholder.com/50?text=Customer',
  })  : lastVisit = lastVisit ?? DateTime.now(),
        joinedAt = joinedAt ?? DateTime.now();
}
