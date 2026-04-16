import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/business_provider.dart';
import '../../widgets/profile/profile_subpage_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<BusinessProvider>().themeColor;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSubpageHeader(
            title: 'Help & Support',
            subtitle: 'FAQs, tips aur contact — BizzWay business app ke liye',
            accent: accent,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _faqTile(
                  'Orders kab update hote hain?',
                  'Jab customer place kare aur aap status change karein — sab orders screen par dikhte hain.',
                ),
                _faqTile(
                  'Delivery riders kaise assign hote hain?',
                  'Team riders screen se IDs add karein; order par assign karke rider ko dikhe ga.',
                ),
                _faqTile(
                  'Bookings vs Orders?',
                  'Salon / clinic / rent-a-car style businesses mein bookings; grocery / restaurant mein orders flow.',
                ),
                const SizedBox(height: 20),
                Text(
                  'Contact',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _contactRow(
                          Icons.email_outlined,
                          'support@bizzway.app',
                        ),
                        const SizedBox(height: 12),
                        _contactRow(
                          Icons.phone_outlined,
                          '0300 — BizzWay (demo)',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hours: Mon–Sat, 10:00 – 18:00 (PKT)',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.95),
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
    );
  }

  Widget _faqTile(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            q,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                a,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

