import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/business_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/order.dart';
import '../../models/job_request.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../widgets/dashboard/dashboard_stat_card.dart';
import '../../widgets/orders/order_card.dart';
import '../../widgets/common/animated_page_transition.dart';
import '../customers/customers_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../profile/profile_screen.dart';
import '../service_worker/job_request_detail_screen.dart';
import '../gym/gym_owner_console_screen.dart';

enum _SalesRange { daily, weekly, monthly, yearly }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final notifCount = context.watch<NotificationProvider>().unreadCount;
    final business = context.watch<BusinessProvider>();
    final themeColor = business.themeColor;
    final isServiceBiz = [
      'salon',
      'gym',
      'clinic',
    ].contains(business.selectedBusiness?.id);

    return Scaffold(
      body: AnimatedPageTransition(
        index: _selectedIndex,
        children: [
          _DashboardHome(onSwitchTab: switchTab),
          const OrdersScreen(),
          const ProductsScreen(),
          const CustomersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 75,
        items: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard_outlined, size: 24, color: Colors.white),
              if (_selectedIndex != 0) ...[
                const SizedBox(height: 2),
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isServiceBiz
                    ? Icons.event_note_outlined
                    : Icons.receipt_long_outlined,
                size: 24,
                color: Colors.white,
              ),
              if (_selectedIndex != 1) ...[
                const SizedBox(height: 2),
                Text(
                  isServiceBiz ? 'Bookings' : 'Orders',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isServiceBiz ? Icons.spa_outlined : Icons.inventory_2_outlined,
                size: 24,
                color: Colors.white,
              ),
              if (_selectedIndex != 2) ...[
                const SizedBox(height: 2),
                Text(
                  isServiceBiz ? 'Services' : 'Products',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 24, color: Colors.white),
              if (_selectedIndex != 3) ...[
                const SizedBox(height: 2),
                const Text(
                  'Customers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 24, color: Colors.white),
              if (_selectedIndex != 4) ...[
                const SizedBox(height: 2),
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
        onTap: switchTab,
        backgroundColor: Colors.transparent,
        color: themeColor,
        animationDuration: const Duration(milliseconds: 400),
        animationCurve: Curves.easeInOut,
      ),
      floatingActionButton: _selectedIndex == 0
          ? Stack(
              alignment: Alignment.topRight,
              children: [
                FloatingActionButton(
                  heroTag: 'notif-fab',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                  backgroundColor: themeColor,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                ),
                if (notifCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$notifCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final void Function(int) onSwitchTab;

  const _DashboardHome({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final customers = context.watch<CustomerProvider>();
    final products = context.watch<ProductProvider>();
    final business = context.watch<BusinessProvider>();
    final jobs = context.watch<JobProvider>();
    final bizId = business.selectedBusiness?.id ?? '';
    final isServiceBiz = ['salon', 'gym', 'clinic'].contains(bizId);
    final isFoodBiz = ['restaurant', 'cafe'].contains(bizId);
    final isNearMeType = business.isNearMeType;
    final scopedJobs = jobs.requestsForBusiness(bizId);
    final scopedOrders = orders.orders
        .where((o) => o.businessTypeId == bizId)
        .toList();
    final scopedPending = orders.pendingOrders
        .where((o) => o.businessTypeId == bizId)
        .toList();
    final scopedProducts = products.productsForBusiness(bizId);
    final headerGradient = AppColors.gradientFrom(business.themeColor);

    return CustomScrollView(
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
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        business.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onSwitchTab(4),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      business.selectedBusiness?.icon ?? Icons.store,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNearMeType) ...[
                  _buildOnlineToggle(context, business),
                  const SizedBox(height: 12),
                  if (scopedJobs.isNotEmpty)
                    _buildJobRequests(
                      context,
                      scopedJobs,
                      jobs,
                      business.themeColor,
                    ),
                  const SizedBox(height: 12),
                ],
                _buildBusinessVisualHeader(
                  context,
                  bizId: bizId,
                  bizName: business.businessName,
                  themeColor: business.themeColor,
                ),
                const SizedBox(height: 14),
                _buildRevenueCard(
                  context,
                  scopedOrders,
                  isServiceBiz,
                  business.themeColor,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    DashboardStatCard(
                      title: isServiceBiz
                          ? 'Total Bookings'
                          : AppStrings.totalOrders,
                      value: '${scopedOrders.length}',
                      icon: Icons.receipt_long,
                      color: AppColors.primary,
                    ),
                    DashboardStatCard(
                      title: AppStrings.totalCustomers,
                      value: '${customers.totalCustomers}',
                      icon: Icons.people,
                      color: AppColors.info,
                    ),
                    DashboardStatCard(
                      title: isServiceBiz
                          ? 'Services'
                          : AppStrings.totalProducts,
                      value: '${scopedProducts.length}',
                      icon: isServiceBiz
                          ? Icons.spa_outlined
                          : Icons.inventory_2,
                      color: AppColors.success,
                    ),
                    DashboardStatCard(
                      title: 'Pending',
                      value: '${scopedPending.length}',
                      icon: Icons.hourglass_empty,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (bizId == 'gym')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: business.themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GymOwnerConsoleScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: business.themeColor,
                                size: 28,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gym desk',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Online admissions — cash accept karke membership start karein',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: business.themeColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                _buildQuickActions(context, isServiceBiz, isFoodBiz),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isServiceBiz
                          ? 'Recent Bookings'
                          : AppStrings.recentOrders,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => onSwitchTab(1),
                      child: const Text(AppStrings.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (scopedOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'No orders yet for this business.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...scopedOrders.take(3).map((o) => OrderCard(order: o)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Online / Offline toggle ───────────────────────────────────────────────

  Widget _buildOnlineToggle(BuildContext context, BusinessProvider biz) {
    final isOnline = biz.isOnline;
    return GestureDetector(
      onTap: () => biz.setOnline(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOnline
                ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                : [const Color(0xFF616161), const Color(0xFF9E9E9E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isOnline ? Colors.green : Colors.grey).withValues(
                alpha: 0.3,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'You are ONLINE' : 'You are OFFLINE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isOnline
                        ? 'Visible in Near Me • Accepting requests'
                        : 'Tap to go online & receive job requests',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isOnline,
              onChanged: (v) => biz.setOnline(v),
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.4),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  // ── Incoming job requests ─────────────────────────────────────────────────

  Widget _buildJobRequests(
    BuildContext context,
    List<JobRequest> scoped,
    JobProvider jobs,
    Color bizColor,
  ) {
    final pending = scoped.where((r) => r.isPending).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Job Requests', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            if (pending.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pending.length} new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...scoped
            .take(4)
            .map(
              (req) => _JobRequestCard(
                req: req,
                bizColor: bizColor,
                onDetails: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JobRequestDetailScreen(request: req),
                  ),
                ),
                onReject: () => jobs.reject(req.id),
                onComplete: () => jobs.complete(req.id),
              ),
            ),
        if (scoped.length > 4) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'View all ${scoped.length} requests',
                style: TextStyle(color: bizColor),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    List<Order> scopedOrders,
    bool isServiceBiz,
    Color themeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientFrom(themeColor),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isServiceBiz ? 'Bookings Analytics' : 'Sales Analytics',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Daily • Weekly • Monthly • Yearly',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelColor: themeColor,
                    unselectedLabelColor: Colors.white,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    tabs: const [
                      Tab(text: 'Daily'),
                      Tab(text: 'Weekly'),
                      Tab(text: 'Monthly'),
                      Tab(text: 'Yearly'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: TabBarView(
                    children: [
                      _buildAnalyticsPanel(scopedOrders, _SalesRange.daily),
                      _buildAnalyticsPanel(scopedOrders, _SalesRange.weekly),
                      _buildAnalyticsPanel(scopedOrders, _SalesRange.monthly),
                      _buildAnalyticsPanel(scopedOrders, _SalesRange.yearly),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPanel(List<Order> scopedOrders, _SalesRange range) {
    final completedOrders = scopedOrders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final rangeOrders = _ordersForRange(completedOrders, range);
    final total = rangeOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final spots = _salesSpots(completedOrders, range);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rs. ${total.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${rangeOrders.length} completed orders in ${_rangeName(range).toLowerCase()} view',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.white.withValues(alpha: 0.9),
                  barWidth: 2.4,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Order> _ordersForRange(List<Order> orders, _SalesRange range) {
    final now = DateTime.now();
    return orders.where((o) {
      final created = o.createdAt;
      switch (range) {
        case _SalesRange.daily:
          final today = DateUtils.dateOnly(now);
          return DateUtils.dateOnly(created) == today;
        case _SalesRange.weekly:
          final start = DateUtils.dateOnly(
            now.subtract(const Duration(days: 6)),
          );
          return !DateUtils.dateOnly(created).isBefore(start);
        case _SalesRange.monthly:
          final start = DateUtils.dateOnly(
            now.subtract(const Duration(days: 29)),
          );
          return !DateUtils.dateOnly(created).isBefore(start);
        case _SalesRange.yearly:
          return !created.isBefore(now.subtract(const Duration(days: 365)));
      }
    }).toList();
  }

  List<FlSpot> _salesSpots(List<Order> orders, _SalesRange range) {
    final now = DateTime.now();

    switch (range) {
      case _SalesRange.daily:
        final buckets = List<double>.filled(6, 0);
        final today = DateUtils.dateOnly(now);
        for (final o in orders) {
          final created = o.createdAt;
          if (DateUtils.dateOnly(created) != today) continue;
          final bucket = (created.hour ~/ 4).clamp(0, 5);
          buckets[bucket] += o.totalAmount;
        }
        return List.generate(6, (i) => FlSpot(i.toDouble(), buckets[i]));

      case _SalesRange.weekly:
        final buckets = List<double>.filled(7, 0);
        final start = DateUtils.dateOnly(now.subtract(const Duration(days: 6)));
        for (final o in orders) {
          final created = DateUtils.dateOnly(o.createdAt);
          final diff = created.difference(start).inDays;
          if (diff >= 0 && diff < 7) {
            buckets[diff] += o.totalAmount;
          }
        }
        return List.generate(7, (i) => FlSpot(i.toDouble(), buckets[i]));

      case _SalesRange.monthly:
        final buckets = List<double>.filled(6, 0);
        final start = DateUtils.dateOnly(
          now.subtract(const Duration(days: 29)),
        );
        for (final o in orders) {
          final created = DateUtils.dateOnly(o.createdAt);
          final diff = created.difference(start).inDays;
          if (diff >= 0 && diff < 30) {
            final bucket = (diff ~/ 5).clamp(0, 5);
            buckets[bucket] += o.totalAmount;
          }
        }
        return List.generate(6, (i) => FlSpot(i.toDouble(), buckets[i]));

      case _SalesRange.yearly:
        final buckets = List<double>.filled(12, 0);
        final currentMonthKey = now.year * 12 + now.month;
        for (final o in orders) {
          final created = o.createdAt;
          final orderMonthKey = created.year * 12 + created.month;
          final diff = currentMonthKey - orderMonthKey;
          if (diff >= 0 && diff < 12) {
            final bucket = 11 - diff;
            buckets[bucket] += o.totalAmount;
          }
        }
        return List.generate(12, (i) => FlSpot(i.toDouble(), buckets[i]));
    }
  }

  String _rangeName(_SalesRange range) {
    switch (range) {
      case _SalesRange.daily:
        return 'Daily';
      case _SalesRange.weekly:
        return 'Weekly';
      case _SalesRange.monthly:
        return 'Monthly';
      case _SalesRange.yearly:
        return 'Yearly';
    }
  }

  Widget _buildBusinessVisualHeader(
    BuildContext context, {
    required String bizId,
    required String bizName,
    required Color themeColor,
  }) {
    final imageUrl = _ownerBizImageUrl(bizId);
    return Container(
      height: 126,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: themeColor.withValues(alpha: 0.2),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeColor,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.56),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bizName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _businessTaglineForOwner(bizId),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ownerBizImageUrl(String bizId) {
    final keyword = switch (bizId) {
      'restaurant' || 'cafe' => 'restaurant,food',
      'grocery' => 'grocery,store',
      'pharmacy' => 'pharmacy,medicine',
      'salon' => 'salon,beauty',
      'gym' => 'gym,fitness',
      'clinic' => 'clinic,hospital',
      'rentacar' => 'car,rental',
      'mechanic' => 'car,repair',
      _ => 'small,business',
    };
    return 'https://source.unsplash.com/900x500/?$keyword';
  }

  String _businessTaglineForOwner(String bizId) {
    switch (bizId) {
      case 'restaurant':
      case 'cafe':
        return 'Fresh orders, fast service';
      case 'grocery':
        return 'Daily essentials always ready';
      case 'pharmacy':
        return 'Trusted care for every home';
      case 'rentacar':
        return 'Drive bookings made simple';
      case 'salon':
      case 'gym':
      case 'clinic':
        return 'Appointments and services in one flow';
      default:
        return 'Manage your business smartly';
    }
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isServiceBiz,
    bool isFoodBiz,
  ) {
    final actions = [
      _QuickAction(
        label: isServiceBiz
            ? 'Add\nService'
            : isFoodBiz
            ? 'Add\nItem'
            : 'Add\nProduct',
        icon: isServiceBiz ? Icons.add_circle_outline : Icons.add_box_outlined,
        color: AppColors.success,
        onTap: () => Navigator.pushNamed(context, AppRoutes.addProduct),
      ),
      if (isFoodBiz)
        _QuickAction(
          label: 'Deals &\nOffers',
          icon: Icons.local_offer_outlined,
          color: Colors.orange,
          onTap: () => onSwitchTab(2),
        ),
      _QuickAction(
        label: isServiceBiz ? 'View\nBookings' : 'View\nOrders',
        icon: Icons.receipt_long_outlined,
        color: AppColors.primary,
        onTap: () => onSwitchTab(1),
      ),
      _QuickAction(
        label: 'Customers',
        icon: Icons.people_outline,
        color: AppColors.info,
        onTap: () => onSwitchTab(3),
      ),
      if (!isFoodBiz)
        _QuickAction(
          label: 'Payment',
          icon: Icons.payment_outlined,
          color: AppColors.accent,
          onTap: () => Navigator.pushNamed(context, AppRoutes.payment),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: actions
              .map(
                (a) => Expanded(
                  child: GestureDetector(
                    onTap: a.onTap,
                    child: Container(
                      margin: EdgeInsets.only(
                        right: actions.last == a ? 0 : 10,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(a.icon, color: a.color, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            a.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: a.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Job Request Card ──────────────────────────────────────────────────────────

class _JobRequestCard extends StatelessWidget {
  final dynamic req; // JobRequest
  final Color bizColor;
  final VoidCallback onDetails;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  const _JobRequestCard({
    required this.req,
    required this.bizColor,
    required this.onDetails,
    required this.onReject,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = req.status == 'pending';
    final isAccepted = req.status == 'accepted';
    final isRejected = req.status == 'rejected';

    Color statusColor = isPending
        ? Colors.orange
        : isAccepted
        ? Colors.green
        : isRejected
        ? Colors.red
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.serviceTypeName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                req.timeAgo,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPending
                      ? 'New'
                      : isAccepted
                      ? 'Accepted'
                      : isRejected
                      ? 'Rejected'
                      : 'Done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            req.issue,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 12,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  req.userAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bizColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isAccepted) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bizColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text(
                  'Mark Complete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
