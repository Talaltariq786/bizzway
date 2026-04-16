import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import 'rider_edit_profile_screen.dart';
import 'rider_legal_screen.dart';
import 'rider_navigation.dart';
import 'rider_settings_screen.dart';

const double _navClearance = 88;

class RiderProfileHub extends StatelessWidget {
  const RiderProfileHub({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final phone = auth.userEmail ?? '—';
    final raw = phone == '—' ? 'R' : phone.trim();
    final char = raw.isNotEmpty ? raw[0].toUpperCase() : 'R';

    return ColoredBox(
      color: AppColors.backgroundLight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, _navClearance),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rider partner',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((auth.riderBike ?? '').isNotEmpty)
                      Text(
                        'Bike: ${auth.riderBike}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _card(
            children: [
              _tile(
                icon: Icons.edit_rounded,
                title: 'Edit profile',
                subtitle: 'Licence, NIC, bike',
                onTap: () => Navigator.push(
                  context,
                  RiderTransitions.slideFromRight(const RiderEditProfileScreen()),
                ),
              ),
              const Divider(height: 1),
              _tile(
                icon: Icons.settings_rounded,
                title: 'Settings',
                subtitle: 'Alerts, legal, log out',
                onTap: () => Navigator.push(
                  context,
                  RiderTransitions.slideFromRight(const RiderSettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            children: [
              _tile(
                icon: Icons.article_outlined,
                title: 'Terms & conditions',
                onTap: () => Navigator.push(
                  context,
                  RiderTransitions.slideFromRight(
                    const RiderLegalScrollScreen(
                      title: 'Terms & conditions',
                      body: riderTermsBody,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _tile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                onTap: () => Navigator.push(
                  context,
                  RiderTransitions.slideFromRight(
                    const RiderLegalScrollScreen(
                      title: 'Privacy policy',
                      body: riderPrivacyBody,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _tile(
                icon: Icons.info_outline_rounded,
                title: 'About ${AppStrings.appName}',
                onTap: () => Navigator.push(
                  context,
                  RiderTransitions.slideFromRight(
                    RiderLegalScrollScreen(
                      title: 'About ${AppStrings.appName}',
                      body: riderAboutBody,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

