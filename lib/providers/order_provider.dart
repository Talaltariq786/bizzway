import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [
    Order(
      id: 'ORD-001',
      customerId: 'c1',
      customerName: 'Ahmed Khan',
      customerPhone: '0300-1234567',
      businessTypeId: 'restaurant',
      businessTypeName: 'Restaurant',
      items: [
        const OrderItem(
          productId: '1',
          productName: 'Classic Burger',
          quantity: 2,
          unitPrice: 450,
        ),
        const OrderItem(
          productId: '3',
          productName: 'Fresh Lemonade',
          quantity: 2,
          unitPrice: 180,
        ),
      ],
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Order(
      id: 'ORD-002',
      customerId: 'c2',
      customerName: 'Sara Ali',
      customerPhone: '0321-9876543',
      businessTypeId: 'grocery',
      businessTypeName: 'Grocery',
      items: [
        const OrderItem(
          productId: '4',
          productName: 'Basmati Rice 5kg',
          quantity: 1,
          unitPrice: 1200,
        ),
        const OrderItem(
          productId: '6',
          productName: 'Cooking Oil 1L',
          quantity: 2,
          unitPrice: 450,
        ),
      ],
      status: OrderStatus.active,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    Order(
      id: 'ORD-003',
      customerId: 'c3',
      customerName: 'Bilal Hassan',
      customerPhone: '0312-5551234',
      businessTypeId: 'restaurant',
      businessTypeName: 'Restaurant',
      items: [
        const OrderItem(
          productId: '2',
          productName: 'Pepperoni Pizza',
          quantity: 1,
          unitPrice: 850,
        ),
        const OrderItem(
          productId: '5',
          productName: 'Chocolate Cake',
          quantity: 2,
          unitPrice: 350,
        ),
      ],
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Order(
      id: 'ORD-004',
      customerId: 'c4',
      customerName: 'Fatima Rizvi',
      customerPhone: '0333-7778899',
      businessTypeId: 'pharmacy',
      businessTypeName: 'Pharmacy',
      items: [
        const OrderItem(
          productId: '10',
          productName: 'Panadol 500mg x20',
          quantity: 2,
          unitPrice: 120,
        ),
        const OrderItem(
          productId: '11',
          productName: 'Vitamin C 1000mg',
          quantity: 1,
          unitPrice: 350,
        ),
      ],
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Order(
      id: 'ORD-005',
      customerId: 'c5',
      customerName: 'Usman Tariq',
      customerPhone: '0345-1122334',
      businessTypeId: 'grocery',
      businessTypeName: 'Grocery',
      items: [
        const OrderItem(
          productId: '7',
          productName: 'Fresh Vegetables Bundle',
          quantity: 1,
          unitPrice: 600,
        ),
      ],
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
    Order(
      id: 'ORD-006',
      customerId: 'c6',
      customerName: 'Zara Mahmood',
      customerPhone: '0311-5566778',
      businessTypeId: 'pharmacy',
      businessTypeName: 'Pharmacy',
      items: [
        const OrderItem(
          productId: '12',
          productName: 'Amoxicillin 500mg',
          quantity: 1,
          unitPrice: 280,
        ),
      ],
      notes: 'Prescription: Dr. Kamran - 26 Mar 2026',
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Order(
      id: 'ORD-007',
      customerId: 'c7',
      customerName: 'Hassan Raza',
      customerPhone: '0322-9988776',
      businessTypeId: 'cafe',
      businessTypeName: 'Café',
      items: [
        const OrderItem(
          productId: '20',
          productName: 'Cappuccino',
          quantity: 2,
          unitPrice: 350,
        ),
        const OrderItem(
          productId: '21',
          productName: 'Croissant',
          quantity: 1,
          unitPrice: 180,
        ),
      ],
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();
  List<Order> get activeOrders =>
      _orders.where((o) => o.status == OrderStatus.active).toList();
  List<Order> get completedOrders =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();
  List<Order> get cancelledOrders =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  /// Returns a map of businessTypeId → list of all orders for that category
  Map<String, List<Order>> get billsByCategory {
    final map = <String, List<Order>>{};
    for (final order in _orders) {
      map.putIfAbsent(order.businessTypeId, () => []).add(order);
    }
    return map;
  }

  List<Order> ordersForCategory(String businessTypeId) =>
      _orders.where((o) => o.businessTypeId == businessTypeId).toList();

  int get totalOrdersCount => _orders.length;
  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.completed)
      .fold(0, (sum, o) => sum + o.totalAmount);

  void updateStatus(String orderId, OrderStatus status, {int? etaMinutes}) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = status;
      if (etaMinutes != null) _orders[index].etaMinutes = etaMinutes;
      notifyListeners();
    }
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }
}
