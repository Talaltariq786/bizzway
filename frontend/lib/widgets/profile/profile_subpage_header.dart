import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/dashboard_header_layout.dart';

/// Gradient header + back — Profile / Help / About subpages.
class ProfileSubpageHeader extends StatelessWidget {
  const ProfileSubpageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.accent,
  });

  final String title;
  final String? subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final headerGradient = AppColors.gradientFrom(accent);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: DashboardHeaderOverlay.inset,
        right: DashboardHeaderOverlay.inset,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

