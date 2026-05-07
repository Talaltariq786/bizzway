import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/business_provider.dart';
import '../../providers/rider_team_provider.dart';

class RiderTeamScreen extends StatefulWidget {
  const RiderTeamScreen({super.key});

  @override
  State<RiderTeamScreen> createState() => _RiderTeamScreenState();
}

class _RiderTeamScreenState extends State<RiderTeamScreen> {
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final biz = context.watch<BusinessProvider>();
    final bizId = biz.selectedBusiness?.id ?? '';
    final team = context.watch<RiderTeamProvider>();
    final riders = team.ridersFor(bizId);
    final plan = biz.subscriptionPlan.trim().isEmpty ? 'free' : biz.subscriptionPlan.trim();
    final maxRiders = plan == 'free' ? 3 : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Team riders'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add rider',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a unique Rider ID for each rider. They sign in with that Rider ID plus '
                  'phone on Team rider login (same values you enter here).',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _id,
                  decoration: const InputDecoration(
                    labelText: 'Rider ID (e.g. rider_01)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: bizId.isEmpty
                        ? null
                        : () async {
                            if (maxRiders != null && riders.length >= maxRiders) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Free plan: max $maxRiders riders. 4th ke liye subscription chahiye.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'Upgrade',
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.payment,
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            final err = await context
                                .read<RiderTeamProvider>()
                                .addRider(
                                  businessId: bizId,
                                  riderId: _id.text,
                                  name: _name.text,
                                  phone: _phone.text,
                                  maxAllowed: maxRiders,
                                );
                            if (!context.mounted) return;
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(err),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            _id.clear();
                            _name.clear();
                            _phone.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rider added'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'My riders',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (riders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                'Abhi koi rider add nahi.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...riders.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Slidable(
                  key: ValueKey('rider_${bizId}_${r.riderId}'),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.38,
                    children: [
                      SlidableAction(
                        onPressed: (_) => _editRiderSheet(
                          context,
                          businessId: bizId,
                          riderId: r.riderId,
                          name: r.name,
                          phone: r.phone,
                        ),
                        backgroundColor: const Color(0xFF1A3A5C),
                        foregroundColor: Colors.white,
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        borderRadius: BorderRadius.circular(16),
                      ),
                      SlidableAction(
                        onPressed: (_) => context
                            .read<RiderTeamProvider>()
                            .removeRider(bizId, r.riderId),
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          Icons.pedal_bike_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        r.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('ID: ${r.riderId} · ${r.phone}'),
                      trailing: const Icon(
                        Icons.swipe_left_rounded,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editRiderSheet(
    BuildContext context, {
    required String businessId,
    required String riderId,
    required String name,
    required String phone,
  }) async {
    final idCtrl = TextEditingController(text: riderId);
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Edit rider',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                labelText: 'Rider ID',
                hintText: 'e.g. rider_01',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final err = await context.read<RiderTeamProvider>().updateRider(
                            businessId: businessId,
                            existingRiderId: riderId,
                            nextRiderId: idCtrl.text,
                            nextName: nameCtrl.text,
                            nextPhone: phoneCtrl.text,
                          );
                      if (!context.mounted) return;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rider updated'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    idCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}

