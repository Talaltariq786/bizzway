import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/owned_rider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/rider_team_provider.dart';

/// Owner apni team ([RiderTeamProvider]) se rider select karta hai.
Future<OwnedRider?> showAssignRiderSheet(
  BuildContext context, {
  required String businessId,
}) {
  final riders = context.read<RiderTeamProvider>().ridersFor(businessId);

  return showModalBottomSheet<OwnedRider>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxListH = MediaQuery.sizeOf(ctx).height * 0.42;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Assign rider',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Profile → Team riders se IDs banayein. Ek rider par ek waqt mein max '
                '${OrderProvider.maxConcurrentAssignmentsPerRider} active deliveries.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 14),
              if (riders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.group_add_rounded,
                        size: 40,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No riders added yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Future.microtask(() {
                            if (context.mounted) {
                              Navigator.pushNamed(context, AppRoutes.riderTeam);
                            }
                          });
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add riders'),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: maxListH.clamp(120.0, 320.0),
                  child: ListView.separated(
                    itemCount: riders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = riders[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(
                            Icons.pedal_bike_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          r.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${r.riderId} · ${r.phone}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint,
                        ),
                        onTap: () => Navigator.pop(ctx, r),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> assignRiderToOrder(BuildContext context, String orderId) async {
  final bizId = context.read<BusinessProvider>().selectedBusiness?.id ?? '';
  final rider = await showAssignRiderSheet(context, businessId: bizId);
  if (rider == null || !context.mounted) return;
  final ok = context.read<OrderProvider>().assignRider(
        orderId,
        riderId: rider.riderId,
        riderName: rider.name,
        riderPhone: rider.phone,
      );
  if (!context.mounted) return;
  if (!ok) {
    final max = OrderProvider.maxConcurrentAssignmentsPerRider;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${rider.name} ke paas pehle se $max active orders hain. '
          'Pehle complete karein, phir naya assign karein.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Rider assign: ${rider.name} (${rider.riderId})'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

