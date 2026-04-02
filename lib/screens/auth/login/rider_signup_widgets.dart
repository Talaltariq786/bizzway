import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';

class RiderDocPickerTile extends StatelessWidget {
  const RiderDocPickerTile({
    super.key,
    required this.label,
    required this.file,
    required this.onTap,
  });

  final String label;
  final XFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: file == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.primary.withValues(alpha: 0.85),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    )
                  : Image.file(
                      File(file!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class RiderWalletAgreementCard extends StatelessWidget {
  const RiderWalletAgreementCard({
    super.key,
    required this.agree,
    required this.onToggle,
    required this.onCheckboxChanged,
  });

  final bool agree;
  final VoidCallback onToggle;
  final ValueChanged<bool?> onCheckboxChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.09),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zaroori tasdeeq (Rs 5,000)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Platform use karte waqt aap ke paas kam az kam Rs 5,000 '
                    '(pocket / wallet) hona lazmi hai — yeh number yahan type nahi hota, '
                    'sirf agreement.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: agree,
                              onChanged: onCheckboxChanged,
                              fillColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected)
                                    ? AppColors.primary
                                    : null,
                              ),
                              checkColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Main agree karta/karti hun — meri jeb mein Rs 5,000 '
                              'mojood hon ge jab main deliveries loon.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
