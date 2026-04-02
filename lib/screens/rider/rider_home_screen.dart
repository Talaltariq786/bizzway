import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/rider_analytics.dart';
import '../../core/routes/app_routes.dart';
import '../../models/job_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import 'rider_job_detail_screen.dart';

/// Only orders whose drop-off is within this distance of the rider hub (km).
const double _riderOrderRadiusKm = 5.0;

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  List<JobRequest> _jobsInRadius(JobProvider jobs, AuthProvider auth) {
    final hubLat = auth.riderHubLat;
    final hubLng = auth.riderHubLng;
    return jobs.all.where((j) {
      if (!j.isRiderJob) return false;
      if (!j.isVisibleToRider) return false;
      if (j.destLat == null || j.destLng == null) return false;
      final d = distanceKm(hubLat, hubLng, j.destLat!, j.destLng!);
      return d <= _riderOrderRadiusKm;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>();
    final auth = context.watch<AuthProvider>();
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Rider'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  'Orders (5 km radius)',
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
            'Restaurant, grocery, pharmacy — jab store order ready kare tab yahan dikhega. '
            'Sirf ${_riderOrderRadiusKm.toStringAsFixed(0)} km radius.',
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
                  'Jab restaurant / store order ready karega tab yahan dikhega. '
                  '${_riderOrderRadiusKm.toStringAsFixed(0)} km radius.',
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

  Color _categoryAccent(String? cat) {
    switch (cat) {
      case 'restaurant':
        return _cRestaurant;
      case 'grocery':
        return _cGrocery;
      case 'pharmacy':
        return _cPharmacy;
      default:
        return AppColors.primary;
    }
  }

  /// Same visual language as [DashboardScreen] revenue / bookings analytics card.
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
                _riderAnalyticsPanel(
                  allJobs,
                  now,
                  dayS,
                  RiderAnalyticsPeriod.today,
                ),
                _riderAnalyticsPanel(
                  allJobs,
                  now,
                  weekS,
                  RiderAnalyticsPeriod.week,
                ),
                _riderAnalyticsPanel(
                  allJobs,
                  now,
                  monthS,
                  RiderAnalyticsPeriod.month,
                ),
                _riderAnalyticsPanel(
                  allJobs,
                  now,
                  yearS,
                  RiderAnalyticsPeriod.year,
                ),
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
              const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 28),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
            ),
          ],
          if (auth.riderWallet != null) ...[
            const SizedBox(height: 4),
            Text(
              'Pocket (min. Rs 5,000): Rs. ${auth.riderWallet!.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12),
            ),
          ],
          if ((auth.riderPlan ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _planLabel(auth.riderPlan!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _planLabel(String id) {
    switch (id) {
      case 'rider_monthly':
        return 'Plan: Monthly (Rs 1,500/mo)';
      case 'rider_six_months':
        return 'Plan: 6 mo × Rs 800 (Rs 4,800)';
      default:
        return 'Plan: $id';
    }
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

  Widget _billLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
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
                  color: _categoryAccent(job.deliveryCategory)
                      .withValues(alpha: 0.12),
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
          if ((job.customerName ?? '').isNotEmpty)
            Text(
              job.customerName!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 4),
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
          if ((job.customerPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.phone_in_talk_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.customerPhone!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (job.grandTotal != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (job.itemsTotal != null)
                    _billLine('Items total', job.itemsTotal!),
                  if (job.deliveryFee != null)
                    _billLine('Delivery charges', job.deliveryFee!),
                  if ((job.serviceFee ?? 0) > 0)
                    _billLine('Service fee', job.serviceFee!),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rs. ${job.grandTotal!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (job.orderItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
              ),
            ),
            ...job.orderItems.map(
              (line) => Text(
                '• $line',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
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
                        MaterialPageRoute(
                          builder: (_) => RiderJobDetailScreen(request: job),
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
}
