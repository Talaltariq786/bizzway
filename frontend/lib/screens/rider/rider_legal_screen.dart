import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// Minimal legal bodies (can be replaced with full text from other app).
const String riderTermsBody = 'Terms & conditions (placeholder).';
const String riderPrivacyBody = 'Privacy policy (placeholder).';
const String riderAboutBody = 'About (placeholder).';

class RiderLegalScrollScreen extends StatelessWidget {
  final String title;
  final String body;

  const RiderLegalScrollScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

