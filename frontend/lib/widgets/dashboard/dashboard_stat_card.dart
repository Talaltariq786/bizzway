import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Owner dashboard: compact tappable summary list (replaces the old 2×2 stat grid).
class DashboardOwnerStatsPanel extends StatelessWidget {
  final Color accentColor;
  final bool isServiceBiz;
  final int ordersCount;
  final int customersCount;
  final int productsCount;
  final int pendingCount;
  final VoidCallback onOrdersTap;
  final VoidCallback onCustomersTap;
  final VoidCallback onProductsTap;
  final VoidCallback onPendingTap;

  const DashboardOwnerStatsPanel({
    super.key,
    required this.accentColor,
    required this.isServiceBiz,
    required this.ordersCount,
    required this.customersCount,
    required this.productsCount,
    required this.pendingCount,
    required this.onOrdersTap,
    required this.onCustomersTap,
    required this.onProductsTap,
    required this.onPendingTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleSmall = Theme.of(context).textTheme.titleSmall;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _StatTile(
            icon: Icons.receipt_long_rounded,
            iconBackground: AppColors.primary.withValues(alpha: 0.12),
            iconColor: AppColors.primary,
            label: isServiceBiz ? 'Total bookings' : 'Total orders',
            subtitle: isServiceBiz
                ? 'Tap to open bookings list'
                : 'Tap to open orders & filters',
            value: '$ordersCount',
            accentStripe: accentColor,
            onTap: onOrdersTap,
            titleStyle: titleSmall,
            subtitleStyle: bodySmall,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          _StatTile(
            icon: Icons.people_rounded,
            iconBackground: AppColors.info.withValues(alpha: 0.12),
            iconColor: AppColors.info,
            label: 'Customers',
            subtitle: 'Saved customers for this business',
            value: '$customersCount',
            accentStripe: accentColor,
            onTap: onCustomersTap,
            titleStyle: titleSmall,
            subtitleStyle: bodySmall,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          _StatTile(
            icon: isServiceBiz ? Icons.spa_rounded : Icons.inventory_2_rounded,
            iconBackground: AppColors.success.withValues(alpha: 0.12),
            iconColor: AppColors.success,
            label: isServiceBiz ? 'Services' : 'Products / menu',
            subtitle: isServiceBiz
                ? 'Manage services & packages'
                : 'Manage catalog & stock',
            value: '$productsCount',
            accentStripe: accentColor,
            onTap: onProductsTap,
            titleStyle: titleSmall,
            subtitleStyle: bodySmall,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          _StatTile(
            icon: Icons.hourglass_top_rounded,
            iconBackground: AppColors.warning.withValues(alpha: 0.14),
            iconColor: const Color(0xFFE65100),
            label: 'Pending',
            subtitle: isServiceBiz
                ? 'Needs your attention first'
                : 'Orders waiting to accept',
            value: '$pendingCount',
            accentStripe: accentColor,
            onTap: onPendingTap,
            titleStyle: titleSmall,
            subtitleStyle: bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String value;
  final Color accentStripe;
  final VoidCallback onTap;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const _StatTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.accentStripe,
    required this.onTap,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentStripe.withValues(alpha: 0.35)),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: titleStyle?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleStyle?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontSize: 20,
                            ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
