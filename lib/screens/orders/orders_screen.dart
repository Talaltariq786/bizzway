import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/business_type.dart';
import '../../models/order.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/orders/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final biz = context.watch<BusinessProvider>();
    final bizId = biz.selectedBusiness?.id;

    List<Order> scoped(List<Order> list) {
      if (bizId == null || bizId.isEmpty) return list;
      return list.where((o) => o.businessTypeId == bizId).toList();
    }

    final all = scoped(orders.orders);
    final pending = scoped(orders.pendingOrders);
    final active = scoped(orders.activeOrders);
    final completed = scoped(orders.completedOrders);

    final billsByCategory = <String, List<Order>>{};
    for (final o in all) {
      billsByCategory.putIfAbsent(o.businessTypeId, () => []).add(o);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.orders),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'All (${all.length})'),
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Completed (${completed.length})'),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_rounded, size: 16),
                  SizedBox(width: 4),
                  Text('Bills'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrderList(orders: all),
          _OrderList(orders: pending),
          _OrderList(orders: active),
          _OrderList(orders: completed),
          _BillsView(billsByCategory: billsByCategory),
        ],
      ),
    );
  }
}

// ── Order list ──────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Order> orders;

  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No orders here',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) => OrderCard(order: orders[i]),
    );
  }
}

// ── Bills view ───────────────────────────────────────────────────────────────

class _BillsView extends StatelessWidget {
  final Map<String, List<Order>> billsByCategory;

  const _BillsView({required this.billsByCategory});

  @override
  Widget build(BuildContext context) {
    if (billsByCategory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('Koi bill nahi abhi tak',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final categoryIds = billsByCategory.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category ke mutabiq Bills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Category tap karen bills dekhne ke liye',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: categoryIds.length,
              itemBuilder: (context, index) {
                final typeId = categoryIds[index];
                final catOrders = billsByCategory[typeId]!;
                final bizType = BusinessType.all.firstWhere(
                  (b) => b.id == typeId,
                  orElse: () => BusinessType(
                    id: typeId,
                    title: catOrders.first.businessTypeName,
                    icon: Icons.store,
                    imageUrl: '',
                    categories: [],
                    color: AppColors.primary,
                  ),
                );
                final totalAmount = catOrders.fold<double>(
                    0, (sum, o) => sum + o.totalAmount);

                return _CategoryBillCard(
                  bizType: bizType,
                  orderCount: catOrders.length,
                  totalAmount: totalAmount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _CategoryBillsScreen(
                        bizType: bizType,
                        orders: catOrders,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBillCard extends StatelessWidget {
  final BusinessType bizType;
  final int orderCount;
  final double totalAmount;
  final VoidCallback onTap;

  const _CategoryBillCard({
    required this.bizType,
    required this.orderCount,
    required this.totalAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bizType.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(bizType.icon, color: bizType.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              bizType.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$orderCount bill${orderCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. ${totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: bizType.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Bills Detail Screen ─────────────────────────────────────────────

class _CategoryBillsScreen extends StatelessWidget {
  final BusinessType bizType;
  final List<Order> orders;

  const _CategoryBillsScreen({
    required this.bizType,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(bizType.icon, color: bizType.color, size: 22),
            const SizedBox(width: 8),
            Text('${bizType.title} Bills'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bizType.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: bizType.color.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bizType.color.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(bizType.icon, color: bizType.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bizType.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${orders.length} orders  •  Total: Rs. ${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bills list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: orders.length,
              itemBuilder: (_, i) => _BillCard(
                order: orders[i],
                accentColor: bizType.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Order order;
  final Color accentColor;

  const _BillCard({required this.order, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_rounded,
                      color: accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(order.status),
              ],
            ),
          ),
          // Items
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.circle,
                      size: 5, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.productName} x${item.quantity}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    'Rs. ${item.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (order.notes != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 16),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(order.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    Color color;
    String label;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        label = 'Pending';
      case OrderStatus.active:
        color = Colors.blue;
        label = 'Active';
      case OrderStatus.completed:
        color = Colors.green;
        label = 'Done';
      case OrderStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
