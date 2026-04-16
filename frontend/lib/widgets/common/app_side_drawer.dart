import 'dart:math' show min;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// One row in [AppSideDrawer] (navigation + optional badge).
class AppSideDrawerItem {
  const AppSideDrawerItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
    this.isSelected = false,
    required this.onTap,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;
}

/// Panel only (no [Drawer] shell). Use with push layout or overlay drawer.
class AppSideDrawerPanel extends StatelessWidget {
  const AppSideDrawerPanel({
    super.key,
    this.headerKicker,
    required this.headerTitle,
    this.headerSubtitle,
    required this.headerGradientColors,
    required this.accentColor,
    required this.items,
    this.footer,
  });

  final String? headerKicker;
  final String headerTitle;
  final String? headerSubtitle;
  final List<Color> headerGradientColors;
  final Color accentColor;
  final List<AppSideDrawerItem> items;
  final List<Widget>? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: headerGradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (headerKicker != null) ...[
                      Text(
                        headerKicker!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      headerTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (headerSubtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        headerSubtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ...items.map((e) => _tile(e)),
                  if (footer != null) ...footer!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(AppSideDrawerItem e) {
    final selected = e.isSelected;
    final iconData = selected ? (e.selectedIcon ?? e.icon) : e.icon;
    return ListTile(
      selected: selected,
      selectedTileColor: accentColor.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        iconData,
        color: selected ? accentColor : AppColors.textSecondary,
      ),
      title: Text(
        e.label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? accentColor : AppColors.textPrimary,
        ),
      ),
      trailing: e.badge == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E3F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                e.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      onTap: e.onTap,
    );
  }
}

/// Standard overlay [Drawer] for [Scaffold.drawer].
class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({
    super.key,
    this.headerKicker,
    required this.headerTitle,
    this.headerSubtitle,
    required this.headerGradientColors,
    required this.accentColor,
    required this.items,
    this.footer,
  });

  final String? headerKicker;
  final String headerTitle;
  final String? headerSubtitle;
  final List<Color> headerGradientColors;
  final Color accentColor;
  final List<AppSideDrawerItem> items;
  final List<Widget>? footer;

  @override
  Widget build(BuildContext context) {
    final w = min(320.0, MediaQuery.sizeOf(context).width * 0.88);
    return Drawer(
      width: w,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surface,
      child: AppSideDrawerPanel(
        headerKicker: headerKicker,
        headerTitle: headerTitle,
        headerSubtitle: headerSubtitle,
        headerGradientColors: headerGradientColors,
        accentColor: accentColor,
        items: items,
        footer: footer,
      ),
    );
  }
}

