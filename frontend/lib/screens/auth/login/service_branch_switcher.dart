import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'login_constants.dart';

class ServiceBranchSwitcher extends StatelessWidget {
  const ServiceBranchSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
    this.riderComingSoon = false,
  });

  final ServiceBranch value;
  final ValueChanged<ServiceBranch> onChanged;
  final bool riderComingSoon;

  @override
  Widget build(BuildContext context) {
    void showRiderComingSoon() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Icon(Icons.lock_clock_rounded, size: 40, color: AppColors.primary),
              const SizedBox(height: 10),
              const Text(
                'Rider app coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Abhi public launch me owner/customer flows live hain. '
                'Rider dispatch + live tracking next update me enable hoga.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BranchChip(
              label: 'Home Services',
              subtitle: 'Electrician, plumber, salon…',
              selected: value == ServiceBranch.home,
              onTap: () => onChanged(ServiceBranch.home),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BranchChip(
              label: 'Riders',
              subtitle: 'Food, grocery, pharmacy',
              selected: value == ServiceBranch.rider,
              onTap: riderComingSoon
                  ? showRiderComingSoon
                  : () => onChanged(ServiceBranch.rider),
              comingSoon: riderComingSoon,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.comingSoon = false,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: selected
                      ? Colors.white
                      : (onTap == null
                          ? AppColors.textHint
                          : AppColors.textPrimary),
                ),
              ),
              if (comingSoon) ...[
                const SizedBox(height: 3),
                Text(
                  'Coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.textHint,
                  ),
                ),
              ] else if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.2,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.88)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
