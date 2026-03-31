import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBusinessHeader(context, business),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'Business Settings',
              children: [
                if (business.hasDelivery)
                  _SettingsTile(
                    icon: Icons.delivery_dining_rounded,
                    label: 'Delivery Settings',
                    subtitle:
                        '${business.deliveryRadiusKm.toStringAsFixed(0)} km • Base Rs ${business.deliveryBaseCharge.toStringAsFixed(0)} • Rs ${business.deliveryPerKmCharge.toStringAsFixed(0)}/km',
                    onTap: () => _editDeliverySettings(context, business),
                  ),
                _SettingsTile(
                  icon: Icons.business_outlined,
                  label: AppStrings.businessName,
                  subtitle: business.businessName,
                  onTap: () => _editBusinessName(context, business),
                ),
                _SettingsTile(
                  icon: Icons.category_outlined,
                  label: 'Business Type',
                  subtitle: business.selectedBusiness?.title ?? 'Not set',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.businessSelection),
                ),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  label: AppStrings.themeColor,
                  subtitle: 'Customize app colors',
                  onTap: () => _showColorPicker(context, business),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: business.themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Account',
              children: [
                _SettingsTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  subtitle: auth.userEmail ?? 'Not set',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  label: AppStrings.changePassword,
                  subtitle: 'Update your password',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Support',
              children: [
                _SettingsTile(
                  icon: Icons.payment_outlined,
                  label: 'Subscription & Billing',
                  subtitle: 'Manage your plan',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.payment),
                ),
                _SettingsTile(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  subtitle: 'FAQs and contact',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  label: 'About BizzWay',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, auth),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  AppStrings.logout,
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'BizzWay v1.0.0 — ${AppStrings.tagline}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHeader(
      BuildContext context, BusinessProvider business) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              business.selectedBusiness?.icon ?? Icons.store,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    business.selectedBusiness?.title ?? 'Business',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _editBusinessName(BuildContext context, BusinessProvider business) {
    final ctrl = TextEditingController(text: business.businessName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Business Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Business Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              business.updateBusinessName(ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, BusinessProvider business) {
    final colors = [
      AppColors.primary,
      const Color(0xFF4CAF50),
      const Color(0xFFFF6B6B),
      const Color(0xFFFF9800),
      const Color(0xFF00BCD4),
      const Color(0xFF9C27B0),
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Theme Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                business.updateThemeColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: business.themeColor == color
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (_) => false);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _editDeliverySettings(
    BuildContext context,
    BusinessProvider business,
  ) {
    var radius = business.deliveryRadiusKm
        .clamp(BusinessProvider.minDeliveryRadiusKm, BusinessProvider.maxDeliveryRadiusKm);
    final baseCtrl =
        TextEditingController(text: business.deliveryBaseCharge.toStringAsFixed(0));
    final perKmCtrl =
        TextEditingController(text: business.deliveryPerKmCharge.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Delivery Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Set your delivery radius and charges (1–5 km).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Radius
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Radius',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text('${radius.toStringAsFixed(0)} km',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              Slider(
                value: radius,
                min: BusinessProvider.minDeliveryRadiusKm,
                max: BusinessProvider.maxDeliveryRadiusKm,
                divisions: 4,
                label: '${radius.toStringAsFixed(0)} km',
                onChanged: (v) => setSheet(() => radius = v),
              ),
              const SizedBox(height: 8),

              // Charges
              TextField(
                controller: baseCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Base delivery charge (Rs.)',
                  hintText: 'e.g. 80',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: perKmCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Per km charge (Rs./km)',
                  hintText: 'e.g. 20',
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final base = double.tryParse(baseCtrl.text.trim()) ??
                            business.deliveryBaseCharge;
                        final perKm =
                            double.tryParse(perKmCtrl.text.trim()) ??
                                business.deliveryPerKmCharge;
                        await business.updateDeliveryRadius(radius);
                        await business.updateDeliveryCharges(base, perKm);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
