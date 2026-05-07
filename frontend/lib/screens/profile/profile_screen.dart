import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/dashboard_header_layout.dart';
import '../../core/constants/stock_photo_catalog.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/common/themed_dialog_wrapper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    final auth = context.watch<AuthProvider>();
    final headerGradient = AppColors.gradientFrom(business.themeColor);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: DashboardHeaderOverlay.inset,
              right: DashboardHeaderOverlay.inset,
              bottom: 16,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.profile,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage business settings and account',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBusinessHeader(context, business),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    title: 'Business Settings',
                    children: [
                      _SettingsTile(
                        icon: Icons.image_outlined,
                        label: 'Cover photo',
                        subtitle: business.businessCoverImagePath.trim().isEmpty
                            ? 'Add cover photo'
                            : 'Change cover photo',
                        onTap: () => _editBusinessCover(context, business),
                      ),
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
                        icon: Icons.schedule_rounded,
                        label: 'Business hours',
                        subtitle: business.formattedHours,
                        onTap: () => _editBusinessHours(context, business),
                      ),
                      _SettingsTile(
                        icon: Icons.storefront_outlined,
                        label: 'Shop manual close',
                        subtitle: business.shopManuallyClosed
                            ? (business.shopClosedReason.isNotEmpty
                                ? 'Abhi band — ${business.shopClosedReason}'
                                : 'Customer ko time ke bawajood band dikhega')
                            : 'Time wali opening; mood/issue par yahan se band karein',
                        onTap: () => _editShopManualClose(context, business),
                      ),
                      _SettingsTile(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Store QR code',
                        subtitle:
                            'Print in shop — customers scan to order on BizzWay',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.storeQr),
                      ),
                      _SettingsTile(
                        icon: Icons.category_outlined,
                        label: 'Business Type',
                        subtitle:
                            '${business.selectedBusiness?.title ?? 'Not set'} · fixed at signup',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Business type account banate waqt set hoti hai — yahan se change nahi hoti.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        trailing: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: AppColors.textHint,
                        ),
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
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.changePassword,
                        ),
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
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.payment),
                      ),
                      _SettingsTile(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        subtitle: 'FAQs and contact',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.helpSupport),
                      ),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        label: 'About BizzWay',
                        subtitle: 'Version 1.0.0',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.aboutBizzway),
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        label: 'Terms & Conditions',
                        subtitle: 'Read terms and backend handoff',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.termsAndConditions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'BizzWay v1.0.0 — ${AppStrings.tagline}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHeader(BuildContext context, BusinessProvider business) {
    final cover = business.businessCoverImagePath.trim();
    final isUrl = cover.startsWith('http://') || cover.startsWith('https://');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        image: cover.isEmpty
            ? null
            : DecorationImage(
                image: isUrl ? NetworkImage(cover) : FileImage(File(cover)),
                fit: BoxFit.cover,
              ),
        gradient: LinearGradient(
          colors: [
            ...AppColors.gradientFrom(business.themeColor),
          ],
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
                if (cover.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tap Cover photo in settings to change',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
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
        ],
      ),
    );
  }

  Future<void> _editBusinessCover(
    BuildContext context,
    BusinessProvider business,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          14,
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
            const SizedBox(height: 12),
            const Text(
              'Cover photo',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose Food HD'),
              subtitle: const Text('Pakistan-style cover images'),
              onTap: () async {
                final urls = StockPhotoCatalog.coverSuggestionsForBusiness(
                  business.selectedBusiness?.id ?? 'restaurant',
                );
                final u = await showModalBottomSheet<String>(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx2) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      MediaQuery.of(ctx2).padding.bottom + 16,
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
                        const SizedBox(height: 12),
                        const Text(
                          'Choose a cover (HD)',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: urls.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (_, i) {
                            final uu = urls[i];
                            return InkWell(
                              onTap: () => Navigator.pop(ctx2, uu),
                              borderRadius: BorderRadius.circular(14),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(uu, fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, u);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_back_outlined),
              title: const Text('Upload from gallery'),
              subtitle: const Text('Use your own shop banner/photo'),
              onTap: () async {
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 2400,
                  maxHeight: 2400,
                  imageQuality: 80,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, file?.path);
              },
            ),
          ],
        ),
      ),
    );
    if (picked == null || picked.trim().isEmpty) return;
    await business.updateBusinessCoverImagePath(picked.trim());
    business.debugLogLocalProfile('profile_coverSaved');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cover photo updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
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
      builder: (_) => wrapDialogWithTheme(
        context,
        accentColor: business.themeColor,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Business Name'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Business Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await business.updateBusinessName(ctrl.text);
                business.debugLogLocalProfile('profile_nameSaved');
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
      builder: (_) => wrapDialogWithTheme(
        context,
        accentColor: business.themeColor,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
      ),
    );
  }

  void _editShopManualClose(BuildContext context, BusinessProvider business) {
    var closed = business.shopManuallyClosed;
    final reasonCtrl = TextEditingController(text: business.shopClosedReason);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom +
                16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  'Shop abhi band (override)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kabhi time “open” ho lekin aap band rakhna chahein (mood, stock, break…) — '
                  'yahan se customer ko “closed” dikhega. Wajah neeche likhein (optional lekin behtar).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: closed,
                  onChanged: (v) => setSheet(() => closed = v),
                  title: const Text('Shop abhi ke liye band'),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: business.themeColor,
                ),
                if (closed) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: 'Wajah (e.g. mood off, jaldi mein, stock count)',
                      hintText: 'Chhota sa reason…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
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
                          await business.setShopManualClose(
                            closed,
                            reason: reasonCtrl.text,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: business.themeColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(reasonCtrl.dispose);
  }

  void _editBusinessHours(BuildContext context, BusinessProvider business) {
    var open = business.openTime;
    var close = business.closeTime;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
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
                'Business hours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Customers ko dikhega ke aap kab open hain.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Opens',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: open,
                    );
                    if (picked != null) setSheet(() => open = picked);
                  },
                  child: Text(
                    MaterialLocalizations.of(ctx).formatTimeOfDay(
                      open,
                      alwaysUse24HourFormat: false,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: business.themeColor,
                    ),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Closes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: close,
                    );
                    if (picked != null) setSheet(() => close = picked);
                  },
                  child: Text(
                    MaterialLocalizations.of(ctx).formatTimeOfDay(
                      close,
                      alwaysUse24HourFormat: false,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: business.themeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                        final openM = open.hour * 60 + open.minute;
                        final closeM = close.hour * 60 + close.minute;
                        if (closeM <= openM) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Closing time opening ke baad honi chahiye (same day).',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        await business.updateHours(open, close);
                        business.debugLogLocalProfile('profile_hoursSaved');
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: business.themeColor,
                        foregroundColor: Colors.white,
                      ),
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

  void _editDeliverySettings(BuildContext context, BusinessProvider business) {
    var radius = business.deliveryRadiusKm.clamp(
      BusinessProvider.minDeliveryRadiusKm,
      BusinessProvider.maxDeliveryRadiusKm,
    );
    final baseCtrl = TextEditingController(
      text: business.deliveryBaseCharge.toStringAsFixed(0),
    );
    final perKmCtrl = TextEditingController(
      text: business.deliveryPerKmCharge.toStringAsFixed(0),
    );

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
                  const Text(
                    'Delivery Radius',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${radius.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                        final base =
                            double.tryParse(baseCtrl.text.trim()) ??
                            business.deliveryBaseCharge;
                        final perKm =
                            double.tryParse(perKmCtrl.text.trim()) ??
                            business.deliveryPerKmCharge;
                        await business.updateDeliveryRadius(radius);
                        await business.updateDeliveryCharges(base, perKm);
                        business.debugLogLocalProfile('profile_deliverySaved');
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
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
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
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textHint)
              : null),
      onTap: onTap,
    );
  }
}
