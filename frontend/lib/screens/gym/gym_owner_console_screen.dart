import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/gym_pakistan_schema.dart';
import '../../models/gym_models.dart';
import '../../providers/business_provider.dart';
import '../../providers/gym_management_provider.dart';

/// Owner: pending online admissions (cash at gym) → accept → membership active.
class GymOwnerConsoleScreen extends StatelessWidget {
  const GymOwnerConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    final gym = context.watch<GymManagementProvider>();
    final bizId = business.selectedBusiness?.id ?? '';
    final color = business.themeColor;

    if (bizId != 'gym') {
      return Scaffold(
        appBar: AppBar(title: const Text('Gym desk')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Yeh section sirf Gym business type ke liye hai. Business selection se Gym choose karein.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pending = gym.pendingForBusiness(bizId);
    final active = gym.activeForBusiness(bizId);
    final supplements = gym.supplementsForBusiness(bizId);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Gym desk'),
          backgroundColor: color,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pending payment'),
              Tab(text: 'Active members'),
              Tab(text: 'Supplement shop'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PendingTab(
              pending: pending,
              color: color,
              onAccept: (id) => gym.acceptCashPayment(id),
            ),
            _ActiveTab(
              active: active,
              color: color,
              onAttendance: (id) => gym.markAttendance(id),
            ),
            _SupplementsTab(supplements: supplements, color: color),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab({
    required this.pending,
    required this.color,
    required this.onAccept,
  });

  final List<GymMemberAdmission> pending;
  final Color color;
  final void Function(String id) onAccept;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return Center(
        child: Text(
          'Koi pending admission nahi.\nCustomer online ticket banaye ga — yahan dikhe ga.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = pending[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  a.ticketCode,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Phone: ${a.phone}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                Text(
                  '${a.packageName} · Rs. ${a.feePkr.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                if (a.trainerPreference != null &&
                    a.trainerPreference!.isNotEmpty)
                  Text(
                    'Trainer note: ${a.trainerPreference}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      onAccept(a.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cash received — membership dates set.',
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.payments_rounded, size: 20),
                    label: const Text('Accept cash & activate'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({
    required this.active,
    required this.color,
    required this.onAttendance,
  });

  final List<GymMemberAdmission> active;
  final Color color;
  final void Function(String id) onAttendance;

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (active.isEmpty) {
      return const Center(
        child: Text(
          'Abhi koi active member yahan list mein nahi.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = active[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${a.packageName} · ${_fmt(a.membershipStart)} → ${_fmt(a.membershipEnd)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Attendance: ${a.attendanceCount}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => onAttendance(a.id),
                  style: OutlinedButton.styleFrom(foregroundColor: color),
                  icon: const Icon(Icons.touch_app_rounded, size: 20),
                  label: const Text('Mark visit (+1)'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupplementsTab extends StatelessWidget {
  const _SupplementsTab({
    required this.supplements,
    required this.color,
  });

  final List<GymSupplementProduct> supplements;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cats = GymPakistanSchema.supplementCategories;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'داخل gym shop — demo stock (PK brands)',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 16),
        ...cats.map((c) {
          final id = c['id']! as String;
          final label = c['label']! as String;
          final items = supplements.where((s) => s.categoryId == id).toList();
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${s.brand} · Rs. ${s.pricePkr.toStringAsFixed(0)}'),
                      trailing: Text(
                        '${s.stockQuantity} pcs',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }
}
