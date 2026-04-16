import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
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
    final bizId = context.watch<BusinessProvider>().selectedBusiness?.id ?? '';
    final team = context.watch<RiderTeamProvider>();
    final riders = team.ridersFor(bizId);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Meray riders'),
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
                  'Yahan rider ka ID banayein (unique). Phir isi ID + phone se rider app me login karega.',
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
                            final err = await context
                                .read<RiderTeamProvider>()
                                .addRider(
                                  businessId: bizId,
                                  riderId: _id.text,
                                  name: _name.text,
                                  phone: _phone.text,
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.pedal_bike_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    r.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('ID: ${r.riderId} · ${r.phone}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.error,
                    onPressed: () => context
                        .read<RiderTeamProvider>()
                        .removeRider(bizId, r.riderId),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

