// Ported from your `Bizzway_rider_sercices` app.
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/config/offline_mode.dart';
import '../../core/demo/investor_demo_fixtures.dart';
import '../../core/demo/presenter_mode.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/rider_analytics.dart';
import '../../models/job_request.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/rider_team_provider.dart';
import 'rider_job_detail_screen.dart';
import 'rider_assigned_order_detail_screen.dart';
import 'rider_navigation.dart';

/// Only orders whose drop-off is within this distance of the rider hub (km).
const double _riderOrderRadiusKm = 5.0;

/// Dashboard jobs + analytics (used inside [RiderShellScreen]).
class RiderDashboardTab extends StatefulWidget {
  const RiderDashboardTab({super.key});

  @override
  State<RiderDashboardTab> createState() => _RiderDashboardTabState();
}

class _RiderDashboardTabState extends State<RiderDashboardTab> {
  static const double _bottomClearance = 88;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final team = context.read<RiderTeamProvider>();
      final orders = context.read<OrderProvider>();
      await team.ensurePlaybackTeamRiderIfNeeded();
      if (auth.isAuthenticated) {
        await orders.refreshFromApi();
      }
      if (auth.isTeamRiderAccount &&
          auth.teamRiderId == kInvestorDemoTeamRiderId &&
          (OfflineMode.enabled || PresenterMode.enabled)) {
        orders.ensureDemoAssignedOrderForTeamRider(auth.teamRiderId!);
      }
    });
  }

  List<Order> _teamAssignedOrdersActive(OrderProvider op, AuthProvider auth) {
    final rid = auth.teamRiderId;
    if (rid == null || rid.trim().isEmpty) return const [];
    final list = op.orders
        .where(
          (o) =>
              o.isDelivery &&
              (o.assignedRiderId ?? '').trim() == rid.trim() &&
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.completed,
        )
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Order> _teamAssignedOrdersCompleted(OrderProvider op, AuthProvider auth) {
    final rid = auth.teamRiderId;
    if (rid == null || rid.trim().isEmpty) return const [];
    final list = op.orders
        .where(
          (o) =>
              o.isDelivery &&
              (o.assignedRiderId ?? '').trim() == rid.trim() &&
              o.status == OrderStatus.completed,
        )
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<JobRequest> _jobsInRadius(JobProvider jobs, AuthProvider auth) {
    final hubLat = auth.riderHubLat;
    final hubLng = auth.riderHubLng;
    return jobs.all.where((j) {
      if (!j.isRiderJob) return false;
      if (!j.isVisibleToRider) return false;
      if (!auth.isOnlineForWork && j.isPending) return false;
      if (j.destLat == null || j.destLng == null) return false;
      final d = distanceKm(hubLat, hubLng, j.destLat!, j.destLng!);
      return d <= _riderOrderRadiusKm;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>();
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final riderJobs = _jobsInRadius(jobs, auth);
    final now = DateTime.now();

    final dayS = riderPeriodSummary(
      jobs.all,
      period: RiderAnalyticsPeriod.today,
      now: now,
    );
    final weekS = riderPeriodSummary(
      jobs.all,
      period: RiderAnalyticsPeriod.week,
      now: now,
    );
    final monthS = riderPeriodSummary(
      jobs.all,
      period: RiderAnalyticsPeriod.month,
      now: now,
    );
    final yearS = riderPeriodSummary(
      jobs.all,
      period: RiderAnalyticsPeriod.year,
      now: now,
    );

    if (auth.isTeamRiderAccount) {
      final activeOrders = _teamAssignedOrdersActive(orders, auth);
      final doneOrders = _teamAssignedOrdersCompleted(orders, auth);
      return ColoredBox(
        color: AppColors.backgroundLight,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, _bottomClearance),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Team rider: ${auth.teamRiderDisplayName ?? 'Rider'} · ID ${auth.teamRiderId}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chal rahe deliveries',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (activeOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Abhi koi active assigned order nahi.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...activeOrders.map(
                (o) => _teamRiderOrderCard(
                  context,
                  o,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RiderAssignedOrderDetailScreen(
                        order: o,
                        isPoolOrder: false,
                      ),
                    ),
                  ),
                ),
              ),
            if (doneOrders.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text(
                'Completed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...doneOrders.take(15).map(
                    (o) => _teamRiderOrderCard(
                      context,
                      o,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RiderAssignedOrderDetailScreen(
                            order: o,
                            isPoolOrder: false,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      );
    }

    return ColoredBox(
      color: AppColors.backgroundLight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, _bottomClearance),
        children: [
          if (!auth.isOnlineForWork) ...[
            _offlineBanner(auth),
            const SizedBox(height: 12),
          ],
          _riderProfileCard(auth),
          const SizedBox(height: 14),
          DefaultTabController(
            length: 4,
            child: _deliveryAnalyticsCard(
              jobs.all,
              now,
              dayS,
              weekS,
              monthS,
              yearS,
            ),
          ),
          const SizedBox(height: 14),
          _summaryCard(
            riderJobs.where((j) => j.isPending).length,
            riderJobs.where((j) => j.isAccepted).length,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Orders (5 km)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${riderJobs.length} near you',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Restaurant / grocery / pharmacy appear when the store is ready. '
            'Personal errands show immediately. '
            'Radius ${_riderOrderRadiusKm.toStringAsFixed(0)} km.',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 8),
          if (riderJobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Errands and store-ready deliveries will show here '
                  '(${_riderOrderRadiusKm.toStringAsFixed(0)} km).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...riderJobs.map((job) => _jobTile(context, job, auth)),
        ],
      ),
    );
  }

  static const Color _cRestaurant = Color(0xFFE91E63);
  static const Color _cGrocery = Color(0xFF2E7D32);
  static const Color _cPharmacy = Color(0xFF00897B);
  static const Color _cErrand = Color(0xFF6D4C41);

  Color _categoryAccent(String? cat) {
    switch (cat) {
      case 'restaurant':
        return _cRestaurant;
      case 'grocery':
        return _cGrocery;
      case 'pharmacy':
        return _cPharmacy;
      case 'errand':
        return _cErrand;
      default:
        return AppColors.primary;
    }
  }

  Widget _deliveryAnalyticsCard(
    List<JobRequest> allJobs,
    DateTime now,
    RiderPeriodSummary dayS,
    RiderPeriodSummary weekS,
    RiderPeriodSummary monthS,
    RiderPeriodSummary yearS,
  ) {
    const themeColor = AppColors.primary;
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
            color: themeColor.withValues(alpha: 0.28),
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
                      'Delivery Analytics',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pedal_bike_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            height: 118,
            child: TabBarView(
              children: [
                _riderAnalyticsPanel(allJobs, now, dayS, RiderAnalyticsPeriod.today),
                _riderAnalyticsPanel(allJobs, now, weekS, RiderAnalyticsPeriod.week),
                _riderAnalyticsPanel(allJobs, now, monthS, RiderAnalyticsPeriod.month),
                _riderAnalyticsPanel(allJobs, now, yearS, RiderAnalyticsPeriod.year),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(RiderAnalyticsPeriod p) {
    switch (p) {
      case RiderAnalyticsPeriod.today:
        return 'daily';
      case RiderAnalyticsPeriod.week:
        return 'weekly';
      case RiderAnalyticsPeriod.month:
        return 'monthly';
      case RiderAnalyticsPeriod.year:
        return 'yearly';
    }
  }

  Widget _riderAnalyticsPanel(
    List<JobRequest> allJobs,
    DateTime now,
    RiderPeriodSummary s,
    RiderAnalyticsPeriod period,
  ) {
    final buckets = riderEarningsBuckets(allJobs, period, now);
    final spots = List.generate(
      buckets.length,
      (i) => FlSpot(i.toDouble(), buckets[i]),
    );
    var maxY = 1.0;
    for (final v in buckets) {
      maxY = math.max(maxY, v);
    }
    if (maxY <= 0) {
      maxY = 100;
    } else {
      maxY *= 1.14;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rs. ${s.earningsPkr.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${s.deliveries} completed delivery(s) in ${_periodLabel(period)} view',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.white.withValues(alpha: 0.92),
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

  Widget _offlineBanner(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.95),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'New job requests are hidden. Go online from the menu or tap below.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => auth.setOnlineForWork(true),
            child: const Text('Go online'),
          ),
        ],
      ),
    );
  }

  Widget _riderProfileCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.two_wheeler_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  auth.userEmail ?? 'Rider',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if ((auth.riderBike ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bike: ${auth.riderBike}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
            ),
          ],
          if (auth.riderWallet != null) ...[
            const SizedBox(height: 4),
            Text(
              'Pocket (min Rs 5,000): Rs. ${auth.riderWallet!.toStringAsFixed(0)}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(int pending, int active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _metric('Pending', '$pending', AppColors.warning)),
          Expanded(child: _metric('Active', '$active', AppColors.success)),
        ],
      ),
    );
  }

  Widget _metric(String title, String value, Color c) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: c,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _jobTile(BuildContext context, JobRequest job, AuthProvider auth) {
    double? km;
    if (job.destLat != null && job.destLng != null) {
      km = distanceKm(
        auth.riderHubLat,
        auth.riderHubLng,
        job.destLat!,
        job.destLng!,
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      _categoryAccent(job.deliveryCategory).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.deliveryCategoryLabel,
                  style: TextStyle(
                    color: _categoryAccent(job.deliveryCategory),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (km != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${km.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                job.timeAgo,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.issue,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.userAddress,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (job.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<JobProvider>().reject(job.id),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        RiderTransitions.slideFromRight(
                          RiderJobDetailScreen(request: job),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Details'),
                  ),
                ),
              ],
            )
          else if (job.isAccepted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.read<JobProvider>().complete(job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark delivered'),
              ),
            ),
        ],
      ),
    );
  }

  static final DateFormat _orderPlacedAtFmt =
      DateFormat('d MMM yyyy · h:mm a');

  Widget _teamRiderOrderCard(
    BuildContext context,
    Order o, {
    required VoidCallback onTap,
  }) {
    final statusColor = switch (o.status) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.active => AppColors.info,
      OrderStatus.completed => AppColors.success,
      OrderStatus.cancelled => AppColors.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      o.statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Rs ${o.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                o.id,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Placed · ${_orderPlacedAtFmt.format(o.createdAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${o.customerName} · ${o.customerPhone}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if ((o.customerAddress ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  o.customerAddress!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Delivery Rs ${o.deliveryCharge.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    o.businessTypeName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

