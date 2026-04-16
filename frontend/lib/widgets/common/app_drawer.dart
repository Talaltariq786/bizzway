import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import 'themed_dialog_wrapper.dart';

class AppDrawer extends StatelessWidget {
  /// When used with [SlidingDrawerShell], pass this instead of relying on
  /// [Navigator.pop] (Material overlay drawer).
  final VoidCallback? onClose;

  /// Switches [DashboardScreen] bottom tab (0–4) instead of pushing a new route.
  final void Function(int tabIndex)? onSelectDashboardTab;

  const AppDrawer({super.key, this.onClose, this.onSelectDashboardTab});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    final auth = context.watch<AuthProvider>();
    final accent = business.themeColor;

    final content = SafeArea(
      child: Column(
        children: [
          _DrawerHeader(
            businessName: business.businessName,
            businessType: business.selectedBusiness?.title ?? 'Business',
            icon: business.selectedBusiness?.icon ?? Icons.store_rounded,
            accent: accent,
            userEmail: auth.userEmail,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _tile(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () => _goDashboardTab(context, 0, AppRoutes.dashboard),
                ),
                _tile(
                  context,
                  icon: Icons.receipt_long_outlined,
                  label: AppStrings.orders,
                  onTap: () => _goDashboardTab(context, 1, AppRoutes.orders),
                ),
                _tile(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: AppStrings.products,
                  onTap: () => _goDashboardTab(context, 2, AppRoutes.products),
                ),
                _tile(
                  context,
                  icon: Icons.people_outline,
                  label: AppStrings.customers,
                  onTap: () =>
                      _goDashboardTab(context, 3, AppRoutes.customers),
                ),
                if (business.hasDelivery)
                  _tile(
                    context,
                    icon: Icons.groups_rounded,
                    label: 'Meray riders',
                    onTap: () => _go(context, AppRoutes.riderTeam),
                  ),
                _tile(
                  context,
                  icon: Icons.notifications_outlined,
                  label: AppStrings.notifications,
                  onTap: () => _go(context, AppRoutes.notifications),
                ),
                _tile(
                  context,
                  icon: Icons.person_outline,
                  label: AppStrings.profile,
                  onTap: () => _goDashboardTab(context, 4, AppRoutes.profile),
                ),
                _tile(
                  context,
                  icon: Icons.qr_code_2_rounded,
                  label: 'Store QR',
                  onTap: () => _go(context, AppRoutes.storeQr),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: Divider(height: 1),
                ),
                _tile(
                  context,
                  icon: Icons.payment_outlined,
                  label: AppStrings.subscription,
                  onTap: () => _go(context, AppRoutes.payment),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: Divider(height: 1),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    AppStrings.logout,
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () => _confirmLogout(context, auth, accent),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${AppStrings.appName} — ${AppStrings.tagline}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );

    if (onClose != null) {
      return content;
    }
    return Drawer(child: content);
  }

  ListTile _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _goDashboardTab(
    BuildContext context,
    int tabIndex,
    String fallbackRoute,
  ) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.pop(context);
    }
    if (onSelectDashboardTab != null) {
      onSelectDashboardTab!(tabIndex);
    } else {
      Navigator.pushNamed(context, fallbackRoute);
    }
  }

  void _go(BuildContext context, String route) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.pop(context);
    }
    Navigator.pushNamed(context, route);
  }

  void _confirmLogout(BuildContext context, AuthProvider auth, Color accent) {
    showDialog(
      context: context,
      builder: (_) => wrapDialogWithTheme(
        context,
        accentColor: accent,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String businessName;
  final String businessType;
  final IconData icon;
  final Color accent;
  final String? userEmail;

  const _DrawerHeader({
    required this.businessName,
    required this.businessType,
    required this.icon,
    required this.accent,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final grad = AppColors.gradientFrom(accent);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  businessType,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((userEmail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userEmail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

