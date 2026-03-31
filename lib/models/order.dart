enum OrderStatus { pending, active, completed, cancelled }

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final double? customerLat;
  final double? customerLng;
  final List<OrderItem> items;
  OrderStatus status;
  final DateTime createdAt;
  String? notes;
  final String businessTypeId;
  final String businessTypeName;
  final double deliveryCharge;
  final bool isDelivery;
  int? etaMinutes; // owner-provided ETA in minutes (for customer visibility)

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    this.customerLat,
    this.customerLng,
    required this.items,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
    this.notes,
    this.businessTypeId = 'restaurant',
    this.businessTypeName = 'Restaurant',
    this.deliveryCharge = 0,
    this.isDelivery = false,
    this.etaMinutes,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get totalAmount => subtotal + deliveryCharge;

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.active:
        return 'Active';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
