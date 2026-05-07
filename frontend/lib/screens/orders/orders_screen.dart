import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/business_type.dart';
import '../../models/order.dart';
import '../../models/job_request.dart';
import '../../providers/business_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/orders/order_card.dart';
import '../../core/constants/dashboard_header_layout.dart';

class OrdersScreen extends StatefulWidget {
  /// When non-null (e.g. from owner dashboard), switches to this orders tab (0–4) once applied.
  final int? initialOrdersTabIndex;
  final VoidCallback? onInitialOrdersTabApplied;

  const OrdersScreen({
    super.key,
    this.initialOrdersTabIndex,
    this.onInitialOrdersTabApplied,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final start = widget.initialOrdersTabIndex;
    final idx = start != null && start >= 0 && start < 5 ? start : 0;
    _tabController = TabController(length: 5, vsync: this, initialIndex: idx);
    _tabController.addListener(() => setState(() {}));
    if (start != null && start >= 0 && start < 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onInitialOrdersTabApplied?.call();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idx = widget.initialOrdersTabIndex;
    if (idx == null) return;
    if (idx < 0 || idx >= _tabController.length) {
      widget.onInitialOrdersTabApplied?.call();
      return;
    }
    // Same request as previous build (e.g. parent rebuild) — avoid duplicate callbacks.
    if (oldWidget.initialOrdersTabIndex == idx) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabController.animateTo(idx);
      widget.onInitialOrdersTabApplied?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final biz = context.watch<BusinessProvider>();
    final bizId = biz.selectedBusiness?.id;
    final themeColor = biz.themeColor;
    final headerGradient = AppColors.gradientFrom(themeColor);

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

    final tabs = [
      ('All', all.length, Icons.grid_view_rounded),
      ('Pending', pending.length, Icons.hourglass_top_rounded),
      ('Active', active.length, Icons.local_shipping_rounded),
      ('Completed', completed.length, Icons.check_circle_rounded),
      ('Bills', billsByCategory.length, Icons.receipt_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerGradient,
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
                left: DashboardHeaderOverlay.inset,
                right: DashboardHeaderOverlay.inset,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.orders,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage incoming orders and billing by category',
                    textAlign: TextAlign.center,
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
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(tabs.length, (index) {
                      final isSelected = _tabController.index == index;
                      final (label, count, icon) = tabs[index];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _tabController.animateTo(index)),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 14,
                                color: isSelected ? themeColor : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? themeColor : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E3F),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
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
          if (_isDeliveryStoreBiz(biz.selectedBusiness?.id))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: _StoreRiderJobsCard(
                  businessTypeId: biz.selectedBusiness!.id,
                  themeColor: themeColor,
                ),
              ),
            ),
          SliverFillRemaining(
            child: Container(
              margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrderList(orders: all),
                  _OrderList(orders: pending),
                  _OrderList(orders: active),
                  _OrderList(orders: completed),
                  _BillsView(billsByCategory: billsByCategory),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isDeliveryStoreBiz(String? id) =>
    id == 'restaurant' || id == 'grocery' || id == 'pharmacy';

/// Restaurant / grocery / pharmacy: accept → preparing → ready, phir rider ko job.
class _StoreRiderJobsCard extends StatelessWidget {
  final String businessTypeId;
  final Color themeColor;

  const _StoreRiderJobsCard({
    required this.businessTypeId,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>().all.where((j) {
      if (!j.isRiderJob) return false;
      if (j.deliveryCategory != businessTypeId) return false;
      if (j.status == 'completed' || j.status == 'rejected') return false;
      return j.merchantFulfillmentStatus != null;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (jobs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded, color: themeColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery → rider',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Accept → Preparing → Ready for rider — tab qareebi rider ko job dikhe gi.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: AppColors.textSecondary.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 10),
          ...jobs.map((j) => _StoreRiderJobRow(job: j, themeColor: themeColor)),
        ],
      ),
    );
  }
}

class _StoreRiderJobRow extends StatelessWidget {
  final JobRequest job;
  final Color themeColor;

  const _StoreRiderJobRow({required this.job, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final jp = context.read<JobProvider>();
    final ms = job.merchantFulfillmentStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.merchantStatusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          if (job.orderItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              job.orderItems.take(2).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          if (ms == JobRequest.merchantAwaiting)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => jp.merchantAcceptDeliveryJob(job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Accept order'),
              ),
            )
          else if (ms == JobRequest.merchantPreparing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => jp.merchantMarkReadyForRider(job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Mark ready for rider'),
              ),
            )
          else if (ms == JobRequest.merchantReadyForRider)
            Row(
              children: [
                Icon(Icons.pedal_bike_rounded, size: 18, color: themeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.status == 'pending'
                        ? 'Riders ko dikhai de raha hai (5 km)'
                        : 'Rider ne pick kar liya',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            SizedBox(height: 12),
            Text(
              'No orders here',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            SizedBox(height: 12),
            Text(
              'Koi bill nahi abhi tak',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
                  0,
                  (sum, o) => sum + o.totalAmount,
                );

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

  const _CategoryBillsScreen({required this.bizType, required this.orders});

  @override
  Widget build(BuildContext context) {
    final totalAmount = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
                color: bizType.color.withValues(alpha: 0.25),
                width: 1,
              ),
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
              itemBuilder: (_, i) =>
                  _BillCard(order: orders[i], accentColor: bizType.color),
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
                  child: Icon(
                    Icons.receipt_rounded,
                    color: accentColor,
                    size: 20,
                  ),
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
                  const Icon(Icons.circle, size: 5, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.productName} x${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Rs. ${item.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
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
                const Icon(
                  Icons.access_time,
                  size: 13,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(order.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
