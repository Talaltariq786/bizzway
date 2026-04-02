import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/business_type.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() =>
      _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Orders',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track and manage your orders',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: AppColors.gradientPrimary,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(4, (index) {
                      final isSelected = _tabCtrl.index == index;
                      final counts = [
                        null,
                        prov.pendingOrders.length,
                        prov.activeOrders.length,
                        prov.completedOrders.length,
                      ];
                      final labels = ['Category', 'Pending', 'Active', 'Delivered'];
                      final icons = [Icons.grid_view_rounded, null, null, null];
              
                      return GestureDetector(
                        onTap: () => _tabCtrl.animateTo(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icons[index] != null) ...[
                                Icon(icons[index], size: 14, color: isSelected ? AppColors.primary : Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                labels[index],
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              if (counts[index] != null && counts[index]! > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E3F),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${counts[index]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Container(
              margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 1: Category grid
                _CategoryTab(billsByCategory: prov.billsByCategory),
                // Tab 2: Pending orders
                _OrderListTab(orders: prov.pendingOrders),
                // Tab 3: Active orders
                _OrderListTab(orders: prov.activeOrders),
                // Tab 4: Delivered orders
                _OrderListTab(orders: prov.completedOrders),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TAB 1: Category grid ──────────────────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  final Map<String, List<Order>> billsByCategory;
  const _CategoryTab({required this.billsByCategory});

  @override
  Widget build(BuildContext context) {
    if (billsByCategory.isEmpty) {
      return const _EmptyState(
        icon: Icons.store_outlined,
        title: 'Koi order nahi abhi tak',
        subtitle: 'Kisi restaurant, grocery ya\npharmacy se order karen',
      );
    }

    final ids = billsByCategory.keys
        .where((id) => !BusinessType.excludedFromCustomerBrowse.contains(id))
        .toList();

    if (ids.isEmpty) {
      return const _EmptyState(
        icon: Icons.store_outlined,
        title: 'Browse categories mein koi bill nahi',
        subtitle:
            'Café / Others ke orders yahan category grid mein show nahi hote.\nBaqi tabs se orders dekh sakte hain.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Category se dekhein',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Category tap karen apne orders dekhne ke liye',
            style:
                TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ids.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, i) {
            final typeId = ids[i];
            final orders = billsByCategory[typeId]!;
            final bizType = _bizType(typeId, orders.first.businessTypeName);
            final total =
                orders.fold<double>(0, (s, o) => s + o.totalAmount);
            final pending = orders
                .where((o) => o.status == OrderStatus.pending)
                .length;

            return _CategoryCard(
              bizType: bizType,
              orderCount: orders.length,
              totalAmount: total,
              pendingCount: pending,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _CategoryDetailScreen(
                    bizType: bizType,
                    orders: orders,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── TAB 2/3/4: Flat order list ────────────────────────────────────────────────

class _OrderListTab extends StatelessWidget {
  final List<Order> orders;
  const _OrderListTab({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Koi order nahi',
        subtitle: 'Is category mein\nabhi koi order nahi',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        final bizType = _bizType(o.businessTypeId, o.businessTypeName);
        return _OrderDetailCard(order: o, color: bizType.color);
      },
    );
  }
}

// ── Category card (grid tile) ─────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final BusinessType bizType;
  final int orderCount;
  final double totalAmount;
  final int pendingCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.bizType,
    required this.orderCount,
    required this.totalAmount,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bizType.color.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: bizType.color.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(bizType.icon, color: bizType.color, size: 30),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.orange, shape: BoxShape.circle),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(bizType.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text('$orderCount order${orderCount == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              'Rs. ${totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: bizType.color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category detail screen ────────────────────────────────────────────────────

class _CategoryDetailScreen extends StatelessWidget {
  final BusinessType bizType;
  final List<Order> orders;
  const _CategoryDetailScreen(
      {required this.bizType, required this.orders});

  @override
  Widget build(BuildContext context) {
    final total = orders.fold<double>(0, (s, o) => s + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(children: [
          Icon(bizType.icon, color: bizType.color, size: 20),
          const SizedBox(width: 8),
          Text('${bizType.title} Orders'),
        ]),
      ),
      body: Column(
        children: [
          // Summary strip
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bizType.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: bizType.color.withValues(alpha: 0.20)),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bizType.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(bizType.icon,
                    color: bizType.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bizType.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    Text(
                      '${orders.length} orders  •  Total: Rs. ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: orders.length,
              itemBuilder: (_, i) => _OrderDetailCard(
                  order: orders[i], color: bizType.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order detail card ─────────────────────────────────────────────────────────

class _OrderDetailCard extends StatelessWidget {
  final Order order;
  final Color color;
  const _OrderDetailCard({required this.order, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: order ID + date + status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_rounded,
                    color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.id,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                    Text(
                      DateFormat('d MMM yyyy  •  h:mm a')
                          .format(order.createdAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
            ]),
          ),
          if (order.etaMinutes != null &&
              (order.status == OrderStatus.active ||
                  order.status == OrderStatus.pending))
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    'ETA: ${order.etaMinutes} min',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, indent: 14, endIndent: 14),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.productName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary)),
                          ),
                          Text('× ${item.quantity}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          Text(
                            'Rs. ${item.total.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ]),
                      ))
                  .toList(),
            ),
          ),

          if (order.notes != null && order.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(order.notes!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ),
              ]),
            ),

          const Divider(height: 1, indent: 14, endIndent: 14),

          // Bill summary: subtotal + delivery + total
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    Text('Rs. ${order.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                  ],
                ),
                // Delivery charge row (only if delivery)
                if (order.isDelivery) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delivery_dining_rounded,
                              size: 13,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          const Text('Delivery Charge',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      Text(
                        order.deliveryCharge > 0
                            ? '+ Rs. ${order.deliveryCharge.toStringAsFixed(0)}'
                            : 'Free',
                        style: TextStyle(
                            fontSize: 13,
                            color: order.deliveryCharge > 0
                                ? AppColors.textPrimary
                                : AppColors.success),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 13,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          const Text('Pickup',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const Text('No charge',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.success)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Grand total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      OrderStatus.pending =>
        ('Pending', Colors.orange, Icons.hourglass_top_rounded),
      OrderStatus.active =>
        ('On the way', Colors.blue, Icons.delivery_dining_rounded),
      OrderStatus.completed =>
        ('Delivered', Colors.green, Icons.check_circle_rounded),
      OrderStatus.cancelled =>
        ('Cancelled', Colors.red, Icons.cancel_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(icon, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

BusinessType _bizType(String typeId, String fallbackTitle) {
  return BusinessType.all.firstWhere(
    (b) => b.id == typeId,
    orElse: () => BusinessType(
      id: typeId,
      title: fallbackTitle,
      icon: Icons.store,
      imageUrl: '',
      categories: [],
      color: AppColors.primary,
    ),
  );
}
