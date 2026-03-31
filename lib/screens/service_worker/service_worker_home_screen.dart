import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import 'job_request_detail_screen.dart';

class ServiceWorkerHomeScreen extends StatelessWidget {
  const ServiceWorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Service Worker'),
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
          if ((auth.serviceProfession ?? '').trim().isEmpty)
            _professionBanner(context, auth),
          _summaryCard(jobs.pending.length, jobs.active.length),
          const SizedBox(height: 10),
          if ((auth.serviceProfession ?? '').isNotEmpty ||
              (auth.serviceNic ?? '').isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if ((auth.serviceImagePath ?? '').isNotEmpty)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: FileImage(File(auth.serviceImagePath!)),
                    )
                  else
                    const Icon(Icons.handyman_rounded,
                        color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${auth.serviceProfession ?? 'Service Worker'}'
                      '${(auth.serviceNic ?? '').isNotEmpty ? ' • CNIC: ${auth.serviceNic}' : ''}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if ((auth.servicePlan ?? '').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.servicePlan!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'Nearby Jobs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._filteredJobs(jobs, auth).map(
            (job) => Container(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          job.serviceTypeName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
                            onPressed: () => jobs.reject(job.id),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JobRequestDetailScreen(request: job),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white),
                            child: const Text('Details'),
                          ),
                        ),
                      ],
                    )
                  else if (job.isAccepted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => jobs.complete(job.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Mark Complete'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _professionBanner(BuildContext context, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Select your profession to see only relevant jobs.',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _pickProfession(context, auth),
            child: const Text('Set Now'),
          )
        ],
      ),
    );
  }

  void _pickProfession(BuildContext context, AuthProvider auth) {
    const options = [
      'Electrician',
      'Plumber',
      'Carpenter',
      'Painter',
      'Mechanic',
      'AC Technician',
    ];
    String selected = options.first;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Profession'),
          content: DropdownButtonFormField<String>(
            value: selected,
            items: options
                .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => setSheet(() => selected = v ?? selected),
            decoration: const InputDecoration(
              labelText: 'Profession',
              prefixIcon: Icon(Icons.handyman_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await auth.setServiceProfessionOnly(selected);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  Iterable<dynamic> _filteredJobs(JobProvider jobs, AuthProvider auth) {
    final profRaw = (auth.serviceProfession ?? '').trim().toLowerCase();
    if (profRaw.isEmpty) return jobs.all;

    // Map the worker's profession to allowed service names
    Set<String> allowedNames;
    if (profRaw.contains('punct') || profRaw.contains('tyre') || profRaw.contains('mechanic')) {
      allowedNames = {'puncture'};
    } else if (profRaw.contains('elec')) {
      allowedNames = {'electrician'};
    } else if (profRaw.contains('plumb')) {
      allowedNames = {'plumber'};
    } else if (profRaw.contains('carp')) {
      allowedNames = {'carpenter'};
    } else if (profRaw.contains('paint')) {
      allowedNames = {'painter'};
    } else if (profRaw.contains('ac')) {
      allowedNames = {'ac technician', 'ac'};
    } else {
      // Fallback to strict exact match on name
      allowedNames = {profRaw};
    }

    return jobs.all.where((j) {
      final name = (j.serviceTypeName).toString().toLowerCase().trim();
      return allowedNames.contains(name);
    });
  }

  Widget _summaryCard(int pending, int active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metric('Pending', '$pending'),
          ),
          Expanded(
            child: _metric('Active', '$active'),
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
