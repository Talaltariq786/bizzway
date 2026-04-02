import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'login_constants.dart';

class ServiceBranchSwitcher extends StatelessWidget {
  const ServiceBranchSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ServiceBranch value;
  final ValueChanged<ServiceBranch> onChanged;

  @override
  Widget build(BuildContext context) {
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
              onTap: () => onChanged(ServiceBranch.rider),
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
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

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
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
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
