import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/constants/app_strings.dart';

class CustomerSideDrawer extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelectTab;
  final VoidCallback onClose;

  const CustomerSideDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();

    final cartCount = cart.hasItems
        ? cart.itemCountForBusiness(cart.businessId!)
        : 0;
    final orderCount = orders.orders.length;
    final signedIn = auth.isAuthenticated && auth.isCustomer;

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.gradientPrimary),
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
                    child: const Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          signedIn ? (auth.userEmail ?? 'Account') : 'Guest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          signedIn ? 'Delivery & bookings' : 'Browse & order locally',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                  _nav(context,
                      icon: Icons.home_outlined, label: 'Home', idx: 0),
                  _nav(context,
                      icon: Icons.near_me_outlined, label: 'Near Me', idx: 1),
                  _nav(
                    context,
                    icon: Icons.shopping_cart_outlined,
                    label: 'Cart',
                    idx: 2,
                    badge: cartCount,
                  ),
                  _nav(
                    context,
                    icon: Icons.calendar_month_outlined,
                    label: 'Bookings',
                    idx: 3,
                  ),
                  _nav(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    idx: 4,
                    badge: orderCount,
                  ),
                  const Divider(height: 22),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text(
                      'Settings',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Theme, notifications, feedback & help',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      onClose();
                      Navigator.pushNamed(context, AppRoutes.customerSettings);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    title: Text(
                      signedIn ? 'Logout' : 'Sign in',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () async {
                      onClose();
                      if (signedIn) {
                        await auth.logout();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (_) => false,
                        );
                      } else {
                        Navigator.pushNamed(context, AppRoutes.login);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                'BizzWay • Customer',
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
    int? badge,
  }) {
    final selected = selectedIndex == idx;
    final fg = selected ? AppColors.primary : AppColors.textPrimary;
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected ? AppColors.primaryLight : Colors.transparent,
      leading: badge != null && badge > 0
          ? Badge(
              label: Text('$badge', style: const TextStyle(fontSize: 9)),
              backgroundColor: const Color(0xFFE91E3F),
              child: Icon(icon, color: fg),
            )
          : Icon(icon, color: fg),
      title: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 13,
        ),
      ),
      onTap: () {
        onSelectTab(idx);
        onClose();
      },
    );
  }
}

