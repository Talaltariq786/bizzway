import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';

class OwnerSideDrawer extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelectTab;
  final VoidCallback onClose;

  const OwnerSideDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final biz = context.watch<BusinessProvider>();
    final auth = context.watch<AuthProvider>();
    final themeColor = biz.themeColor;

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientFrom(themeColor),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      biz.selectedBusiness?.icon ?? Icons.store,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          biz.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.userEmail ?? 'Owner',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
                children: [
                  _nav(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    idx: 0,
                  ),
                  _nav(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders / Bookings',
                    idx: 1,
                  ),
                  _nav(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label: 'Products / Services',
                    idx: 2,
                  ),
                  _nav(
                    context,
                    icon: Icons.people_outline,
                    label: 'Customers',
                    idx: 3,
                  ),
                  _nav(
                    context,
                    icon: Icons.person_outline,
                    label: 'Profile',
                    idx: 4,
                  ),
                  const Divider(height: 22),
                  _tile(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      onClose();
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                  ),
                  _tile(
                    context,
                    icon: Icons.payment_outlined,
                    label: 'Subscription / Payment',
                    onTap: () {
                      onClose();
                      Navigator.pushNamed(context, AppRoutes.payment);
                    },
                  ),
                  const SizedBox(height: 6),
                  _tile(
                    context,
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    danger: true,
                    onTap: () async {
                      onClose();
                      await auth.logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                'BizzWay • Owner',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint.withValues(alpha: 0.95),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int idx,
  }) {
    return _tile(
      context,
      icon: icon,
      label: label,
      selected: selectedIndex == idx,
      onTap: () {
        onSelectTab(idx);
        onClose();
      },
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    bool danger = false,
  }) {
    final bg = selected
        ? AppColors.primaryLight
        : Colors.transparent;
    final fg = danger
        ? AppColors.error
        : selected
            ? AppColors.primary
            : AppColors.textPrimary;

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: bg,
      leading: Icon(icon, color: fg),
      title: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }
}

