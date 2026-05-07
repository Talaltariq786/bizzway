import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/api_paths.dart';
import '../core/config/offline_mode.dart';
import '../core/demo/investor_demo_fixtures.dart';
import '../core/demo/presenter_mode.dart';
import '../core/utils/dev_log.dart';
import '../models/order.dart';
import 'job_provider.dart';

class OrderProvider extends ChangeNotifier {
  /// Keep in sync with `bizzwaybackend/src/config/order_policy.ts`.
  static const int maxConcurrentAssignmentsPerRider = 3;

  final List<Order> _orders = [];

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

  /// Replaces in-memory orders with `GET /api/orders` (role-filtered on server).
  /// Call after login from owner / customer / rider screens.
  Future<void> refreshFromApi() async {
    if (OfflineMode.enabled) {
      // Offline: keep any locally-generated orders; no API sync.
      return;
    }
    try {
      final raw = await ApiClient().getJsonList(ApiPaths.orders);
      final mapped = <Order>[];
      for (final e in raw) {
        if (e is Map) {
          final o = _orderFromApi(Map<String, dynamic>.from(e));
          if (o != null) mapped.add(o);
        }
      }
      _orders
        ..clear()
        ..addAll(mapped);
      notifyListeners();
    } catch (e, st) {
      devLog('OrderProvider.refreshFromApi', e, st);
    }
  }

  static Order? _orderFromApi(Map<String, dynamic> m) {
    final itemsRaw = m['items'];
    if (itemsRaw is! List) return null;
    final items = <OrderItem>[];
    for (final it in itemsRaw) {
      if (it is Map) {
        final mm = it.cast<String, dynamic>();
        items.add(
          OrderItem(
            productId: (mm['productId'] ?? '').toString(),
            productName: (mm['name'] ?? '').toString(),
            quantity: (mm['qty'] as num?)?.toInt() ?? 1,
            unitPrice: (mm['unitPrice'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }

    final statusStr = (m['status'] ?? 'pending').toString();
    OrderStatus st;
    switch (statusStr) {
      case 'pending':
        st = OrderStatus.pending;
        break;
      case 'cancelled':
        st = OrderStatus.cancelled;
        break;
      case 'delivered':
        st = OrderStatus.completed;
        break;
      default:
        st = OrderStatus.active;
    }

    final cid = (m['customerId'] ?? '').toString();
    final short = cid.length > 6 ? cid.substring(cid.length - 6) : cid;

    return Order(
      id: (m['id'] ?? '').toString(),
      customerId: cid,
      customerName: 'Customer ${short.isNotEmpty ? '#$short' : ''}'.trim(),
      customerPhone: '',
      items: items,
      status: st,
      createdAt: DateTime.tryParse((m['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      notes: m['deliveryAddress']?.toString(),
      businessTypeId: () {
        final t = (m['businessType'] ?? '').toString().trim();
        return t.isEmpty ? 'restaurant' : t;
      }(),
      businessTypeName: (m['businessName'] ?? 'Shop').toString(),
      deliveryCharge: (m['deliveryFee'] as num?)?.toDouble() ?? 0,
      isDelivery: true,
      assignedRiderId: m['assignedRiderId']?.toString(),
    );
  }

  void updateStatus(
    String orderId,
    OrderStatus status, {
    int? etaMinutes,
    JobProvider? jobProvider,
  }) {
    if (orderId.trim().isEmpty) return;
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    _orders[index].status = status;
    if (etaMinutes != null) _orders[index].etaMinutes = etaMinutes;
    if (status == OrderStatus.completed && jobProvider != null) {
      try {
        jobProvider.completeRiderJobLinkedToOrder(orderId);
      } catch (e, st) {
        devLog('OrderProvider: rider job sync skipped', e, st);
      }
    }
    notifyListeners();
  }

  /// Counts non-terminal orders assigned to [riderId], excluding [excludeOrderId] (for reassignment).
  int activeAssignmentCountForRider(
    String riderId, {
    String? excludeOrderId,
  }) {
    final id = riderId.trim();
    if (id.isEmpty) return 0;
    return _orders.where((o) {
      if ((o.assignedRiderId ?? '').trim() != id) return false;
      if (excludeOrderId != null && o.id == excludeOrderId) return false;
      return o.status != OrderStatus.completed && o.status != OrderStatus.cancelled;
    }).length;
  }

  /// Returns `false` if rider already has [maxConcurrentAssignmentsPerRider] active orders.
  bool assignRider(
    String orderId, {
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;
    if (activeAssignmentCountForRider(riderId, excludeOrderId: orderId) >=
        maxConcurrentAssignmentsPerRider) {
      return false;
    }
    final o = _orders[index];
    o.assignedRiderId = riderId;
    o.assignedRiderName = riderName;
    o.assignedRiderPhone = riderPhone;
    notifyListeners();
    return true;
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  /// Local demo: assigned grocery order so Team rider home is non-empty (Presenter / offline).
  void ensureDemoAssignedOrderForTeamRider(String riderId) {
    if (riderId.trim() != kInvestorDemoTeamRiderId) return;
    if (!OfflineMode.enabled && !PresenterMode.enabled) return;
    const demoId = 'ORD-DEMO-RIDER-001';
    final demo = investorDemoDeliveryOrderForAssign();
    final i = _orders.indexWhere((o) => o.id == demoId);
    if (i != -1) {
      _orders[i].assignedRiderId = demo.assignedRiderId;
      _orders[i].assignedRiderName = demo.assignedRiderName;
      _orders[i].assignedRiderPhone = demo.assignedRiderPhone;
      notifyListeners();
      return;
    }
    addOrder(demo);
  }
}
