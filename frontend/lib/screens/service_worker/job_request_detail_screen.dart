import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final jobs = context.read<JobProvider>();
    await showAppLoader(context, message: 'Accepting...');
    if (!mounted) return;
    try {
      jobs.accept(widget.request.id, estimatedMins: eta);
    } finally {
      if (mounted) hideAppLoader(context);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _reject() async {
    final jobs = context.read<JobProvider>();
    await showAppLoader(context, message: 'Rejecting...');
    if (!mounted) return;
    try {
      jobs.reject(widget.request.id);
    } finally {
      if (mounted) hideAppLoader(context);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _complete() async {
    final jobs = context.read<JobProvider>();
    await showAppLoader(context, message: 'Marking complete...');
    if (!mounted) return;
    try {
      jobs.complete(widget.request.id);
    } finally {
      if (mounted) hideAppLoader(context);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  String _statusTitle(JobRequest r) {
    if (r.isCompleted) return 'Completed job';
    if (r.isRejected) return 'Rejected request';
    if (r.isAccepted) return 'Active job';
    return 'Request details';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: Text(_statusTitle(r))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusChipRow(r),
          const SizedBox(height: 12),
          _mainCard(r),
          if (r.isCompleted) ...[
            const SizedBox(height: 14),
            _completedInfoCard(r),
          ] else if (r.isRejected) ...[
            const SizedBox(height: 14),
            _rejectedInfoCard(),
          ] else if (r.isAccepted) ...[
            const SizedBox(height: 14),
            _activeJobActions(r),
          ] else ...[
            const SizedBox(height: 14),
            _pendingRespondCard(),
          ],
        ],
      ),
    );
  }

  Widget _statusChipRow(JobRequest r) {
    Color bg;
    Color fg;
    String label;
    if (r.isCompleted) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      label = 'Completed';
    } else if (r.isRejected) {
      bg = AppColors.error.withValues(alpha: 0.1);
      fg = AppColors.error;
      label = 'Rejected';
    } else if (r.isAccepted) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      label = 'In progress';
    } else {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
      label = 'Pending';
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _mainCard(JobRequest r) {
    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userAddress,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (r.destLat != null && r.destLng != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Coordinates: ${r.destLat!.toStringAsFixed(5)}, ${r.destLng!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => openDirections(
                  context: context,
                  address: r.userAddress,
                  lat: r.destLat,
                  lng: r.destLng,
                ),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Navigate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completedInfoCard(JobRequest r) {
    final when = r.completedAt;
    final formatted = when != null
        ? DateFormat('MMM d, yyyy h:mm a').format(when)
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
              SizedBox(width: 8),
              Text(
                'Yeh job complete ho chuki hai',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (formatted != null) ...[
            const SizedBox(height: 8),
            Text(
              'Completed: $formatted',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectedInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.block_rounded, color: AppColors.error, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yeh request reject ho chuki hai — accept/reject wapas nahi.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeJobActions(JobRequest r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'ETA: ${r.estimatedMins ?? '—'} min',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark complete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingRespondCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set ETA & respond',
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
    );
  }
}
