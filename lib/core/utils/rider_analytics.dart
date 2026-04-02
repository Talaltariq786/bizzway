import '../../models/job_request.dart';

/// Completed rider deliveries + earnings for a time window.
class RiderPeriodSummary {
  final int deliveries;
  final double earningsPkr;

  const RiderPeriodSummary(this.deliveries, this.earningsPkr);
}

enum RiderAnalyticsPeriod { today, week, month, year }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whether a completed rider job falls in the analytics window (matches chart buckets).
bool riderJobInAnalyticsPeriod(
  JobRequest j,
  RiderAnalyticsPeriod period,
  DateTime now,
) {
  if (!j.isRiderJob || !j.isCompleted || j.completedAt == null) return false;
  final t = j.completedAt!;
  switch (period) {
    case RiderAnalyticsPeriod.today:
      return t.year == now.year && t.month == now.month && t.day == now.day;
    case RiderAnalyticsPeriod.week:
      final start = _dateOnly(now.subtract(const Duration(days: 6)));
      return !_dateOnly(t).isBefore(start);
    case RiderAnalyticsPeriod.month:
      return t.year == now.year && t.month == now.month;
    case RiderAnalyticsPeriod.year:
      return t.year == now.year;
  }
}

/// Analytics from completed rider jobs (`completedAt` + `grandTotal`).
RiderPeriodSummary riderPeriodSummary(
  List<JobRequest> all, {
  required RiderAnalyticsPeriod period,
  required DateTime now,
}) {
  double sum = 0;
  var count = 0;
  for (final j in all) {
    if (!riderJobInAnalyticsPeriod(j, period, now)) continue;
    count++;
    sum += j.grandTotal ?? 0;
  }
  return RiderPeriodSummary(count, sum);
}

/// Bucketed earnings (PKR) for chart — same jobs as [riderPeriodSummary].
List<double> riderEarningsBuckets(
  List<JobRequest> all,
  RiderAnalyticsPeriod period,
  DateTime now,
) {
  final jobs =
      all.where((j) => riderJobInAnalyticsPeriod(j, period, now)).toList();

  double amount(JobRequest j) => j.grandTotal ?? 0;

  switch (period) {
    case RiderAnalyticsPeriod.today:
      final buckets = List<double>.filled(6, 0);
      final today = _dateOnly(now);
      for (final j in jobs) {
        final t = j.completedAt!;
        if (_dateOnly(t) != today) continue;
        final bucket = (t.hour ~/ 4).clamp(0, 5);
        buckets[bucket] += amount(j);
      }
      return buckets;

    case RiderAnalyticsPeriod.week:
      final buckets = List<double>.filled(7, 0);
      final start = _dateOnly(now.subtract(const Duration(days: 6)));
      for (final j in jobs) {
        final c = _dateOnly(j.completedAt!);
        final diff = c.difference(start).inDays;
        if (diff >= 0 && diff < 7) {
          buckets[diff] += amount(j);
        }
      }
      return buckets;

    case RiderAnalyticsPeriod.month:
      final buckets = List<double>.filled(6, 0);
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      for (final j in jobs) {
        final t = j.completedAt!;
        final d = t.day;
        final bucket = ((d - 1) * 6 ~/ lastDay).clamp(0, 5);
        buckets[bucket] += amount(j);
      }
      return buckets;

    case RiderAnalyticsPeriod.year:
      final buckets = List<double>.filled(12, 0);
      final currentMonthKey = now.year * 12 + now.month;
      for (final j in jobs) {
        final t = j.completedAt!;
        final orderMonthKey = t.year * 12 + t.month;
        final diff = currentMonthKey - orderMonthKey;
        if (diff >= 0 && diff < 12) {
          final bucket = 11 - diff;
          buckets[bucket] += amount(j);
        }
      }
      return buckets;
  }
}
