import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/customer_brand_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_preferences_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/themed_dialog_wrapper.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  static String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final prefs = context.watch<CustomerPreferencesProvider>();
    final auth = context.watch<AuthProvider>();
    final isSignedIn = auth.isAuthenticated && auth.isCustomer;
    final grad = context.customerBrand.headerGradient;
    final light = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor:
          light ? Colors.white : Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(gradient: grad),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionCard(
                  title: 'Account',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsRow(
                        icon: Icons.person_rounded,
                        title: isSignedIn ? 'Signed in' : 'Guest',
                        subtitle: isSignedIn
                            ? (auth.userEmail ?? '—')
                            : 'Sign in to sync orders & addresses',
                        showChevron: false,
                      ),
                      if (!isSignedIn)
                        _SettingsRow(
                          icon: Icons.login_rounded,
                          title: 'Sign in',
                          subtitle: 'Save orders & addresses',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.login),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Text(
                            'Logout: use the side menu (☰).',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Appearance',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _showThemeSheet(context, theme),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: grad,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.accentColor
                                            .withValues(alpha: 0.28),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.palette_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Theme',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Now: ${_themeLabel(theme.mode)} · tap to change',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              showCustomerAccentPickerDialog(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.accentColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.color_lens_rounded,
                                    color: theme.accentColor.computeLuminance() >
                                            0.65
                                        ? Colors.black87
                                        : Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'App accent color',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Buttons, nav bar & highlights — poori app',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                        child: Text(
                          'Pehle light/dark choose karein; phir jo rang pasand ho accent mein set karein — puri app update ho jati hai.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: AppColors.textHint.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Notifications',
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                      theme.accentColor,
                                      Colors.white,
                                      0.88,
                                    ) ??
                                    AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: theme.accentColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Push notifications',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Orders, offers & booking alerts',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: prefs.pushNotificationsEnabled,
                              onChanged: (v) => prefs.setPushNotifications(v),
                              activeThumbColor: Colors.white,
                              activeTrackColor: theme.accentColor,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor:
                                  AppColors.textHint.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 70,
                        endIndent: 16,
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                      _SettingsRow(
                        icon: Icons.inbox_outlined,
                        title: 'Notification inbox',
                        subtitle: prefs.pushNotificationsEnabled
                            ? 'See all your alerts'
                            : 'Push is off — turn on above for alerts',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.notifications,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Legal & support',
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        subtitle: 'Rules, privacy & handoff notes',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.termsAndConditions,
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.feedback_outlined,
                        title: 'Feedback & complaints',
                        subtitle: 'Bugs, bad experience, or suggestions',
                        onTap: () => showCustomerFeedbackSheet(context),
                      ),
                      _SettingsRow(
                        icon: Icons.support_agent_rounded,
                        title: 'Help & Support',
                        subtitle: 'FAQs and contact',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.helpSupport,
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About BizzWay',
                        subtitle: 'Version & what the app does',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.aboutBizzway,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, ThemeProvider themeProv) {
    final grad = context.customerBrand.headerGradient;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom > 0 ? 0 : 8),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: grad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose theme',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BizzWay adapts to your choice — try what feels best.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Column(
                    children: [
                      _ThemeSheetTile(
                        icon: Icons.brightness_auto_rounded,
                        title: 'System',
                        subtitle: 'Match phone light / dark',
                        selected: themeProv.mode == ThemeMode.system,
                        onTap: () async {
                          await themeProv.setMode(ThemeMode.system);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                      _ThemeSheetTile(
                        icon: Icons.light_mode_rounded,
                        title: 'Light',
                        subtitle: 'Bright surfaces, easy in daylight',
                        selected: themeProv.mode == ThemeMode.light,
                        onTap: () async {
                          await themeProv.setMode(ThemeMode.light);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                      _ThemeSheetTile(
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark',
                        subtitle: 'Easier on eyes at night',
                        selected: themeProv.mode == ThemeMode.dark,
                        onTap: () async {
                          await themeProv.setMode(ThemeMode.dark);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Curated, app-friendly accents (not too neon); small circles in the dialog.
const _kAccentPalette = <Color>[
  Color(0xFF6C63FF), // violet (default)
  Color(0xFF5C6BC0), // indigo
  Color(0xFF3949AB), // deep indigo
  Color(0xFF1E88E5), // blue
  Color(0xFF039BE5), // light blue
  Color(0xFF00897B), // teal
  Color(0xFF43A047), // green
  Color(0xFF7CB342), // olive green
  Color(0xFF00ACC1), // cyan
  Color(0xFF546E7A), // blue grey
  Color(0xFF5D4037), // brown
  Color(0xFFD84315), // deep orange
  Color(0xFFFFA726), // amber
  Color(0xFFEC407A), // pink
  Color(0xFF8E24AA), // purple
  Color(0xFF37474F), // blue grey dark
];

Color _iconOnAccent(Color bg) =>
    bg.computeLuminance() > 0.62 ? Colors.black87 : Colors.white;

void showCustomerAccentPickerDialog(BuildContext context) {
  final tp = context.read<ThemeProvider>();

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => wrapDialogWithTheme(
      dialogCtx,
      accentColor: tp.accentColor,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('App accent color'),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _kAccentPalette.map((color) {
                final selected =
                    tp.accentColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () async {
                    await tp.setAccentColor(color);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.border.withValues(alpha: 0.85),
                        width: selected ? 2.2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: _iconOnAccent(color),
                            size: 16,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(4, top + 6, 16, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Account, look & feel, and help',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: light ? Colors.white : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textHint.withValues(alpha: 0.95),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron && onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSheetTile extends StatelessWidget {
  const _ThemeSheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? AppColors.primaryLight.withValues(alpha: 0.85)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a sheet to write feedback; sends via the device email app (`mailto:`).
void showCustomerFeedbackSheet(BuildContext context) {
  final ctrl = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      final safeBottom = MediaQuery.paddingOf(ctx).bottom;
      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safeBottom),
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.light
                ? Colors.white
                : Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Feedback & complaints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Issue, suggestion, ya complaint — neeche likhein; email app se bhej sakte hain.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 6,
                maxLength: 1500,
                decoration: InputDecoration(
                  hintText: 'Yahan likhein…',
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pehle kuch likhein'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  final uri = Uri.parse(
                    'mailto:support@bizzway.app?subject=${Uri.encodeComponent('BizzWay — Customer feedback')}&body=${Uri.encodeComponent(text)}',
                  );
                  try {
                    final ok = await canLaunchUrl(uri);
                    if (ok) {
                      await launchUrl(uri);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Email app nahi khul saka — support@bizzway.app par manually likhein',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email open nahi ho saka')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Send via email'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(ctrl.dispose);
}
