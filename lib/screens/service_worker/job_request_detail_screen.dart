import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_request.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../core/utils/maps.dart';

class JobRequestDetailScreen extends StatefulWidget {
  final JobRequest request;
  const JobRequestDetailScreen({super.key, required this.request});

  @override
  State<JobRequestDetailScreen> createState() => _JobRequestDetailScreenState();
}

class _JobRequestDetailScreenState extends State<JobRequestDetailScreen> {
  final TextEditingController _etaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _etaCtrl.text =
        widget.request.estimatedMins != null ? '${widget.request.estimatedMins}' : '';
  }

  @override
  void dispose() {
    _etaCtrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final eta = int.tryParse(_etaCtrl.text.trim()) ?? 15;
    await showAppLoader(context, message: 'Accepting...');
    try {
      context.read<JobProvider>().accept(widget.request.id, estimatedMins: eta);
    } finally {
      hideAppLoader(context);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reject() async {
    await showAppLoader(context, message: 'Rejecting...');
    try {
      context.read<JobProvider>().reject(widget.request.id);
    } finally {
      hideAppLoader(context);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Request Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.serviceTypeName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    r.timeAgo,
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ]),
                const SizedBox(height: 10),
                const Text(
                  'Issue',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r.issue,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.userAddress,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => openDirections(
                        context: context,
                        address: r.userAddress,
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set ETA & Respond',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _etaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ETA (minutes)',
                    hintText: 'e.g. 20',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white),
                        label: const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
