// Ported from your `Bizzway_rider_sercices` app: rider shell with animated drawer + curved bottom nav.
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import 'rider_dashboard_tab.dart';
import 'rider_profile_hub.dart';
import 'rider_wallet_tab.dart';

/// Rider home: animated drawer, curved bottom bar, dashboard / wallet / profile.
class RiderShellScreen extends StatefulWidget {
  const RiderShellScreen({super.key});

  @override
  State<RiderShellScreen> createState() => _RiderShellScreenState();
}

class _RiderShellScreenState extends State<RiderShellScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<_RiderSideDrawerState> _riderDrawerKey =
      GlobalKey<_RiderSideDrawerState>();

  /// Must match [_RiderSideDrawerState._width].
  static const double _kDrawerWidth = 300;

  late final AnimationController _drawerCtrl;

  int _tab = 0;

  static const _titles = ['Dashboard', 'Wallet', 'Profile'];

  @override
  void initState() {
    super.initState();
    _drawerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _drawerCtrl.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _riderDrawerKey.currentState?.replayOpenAnimation();
    _drawerCtrl.forward();
  }

  void _closeDrawer() {
    _drawerCtrl.reverse();
  }

  void _goTab(int i) {
    setState(() => _tab = i);
    _closeDrawer();
  }

  /// Tutorial-style: slide + slight scale + rounded left edge on the main panel.
  Widget _animatedMainPanel(Widget child, double t) {
    final curved = Curves.easeOutCubic.transform(t);
    final radius = 22.0 * curved;
    final scale = 1.0 - 0.055 * curved;

    return Transform.translate(
      offset: Offset(_kDrawerWidth * curved, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Material(
            color: AppColors.backgroundLight,
            elevation: 18 * curved,
            shadowColor: Colors.black.withValues(alpha: 0.45),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildMainShell(AuthProvider auth) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: AnimatedBuilder(
          animation: _drawerCtrl,
          builder: (context, _) {
            final open = _drawerCtrl.value > 0.35;
            return IconButton(
              icon: Icon(open ? Icons.close_rounded : Icons.menu_rounded),
              tooltip: open ? 'Close menu' : 'Menu',
              onPressed: open ? _closeDrawer : _openDrawer,
            );
          },
        ),
        title: Text(_titles[_tab]),
        actions: [
          IconButton(
            tooltip: auth.isOnlineForWork
                ? 'Online — tap to go offline'
                : 'Offline — tap to go online',
            icon: Icon(
              auth.isOnlineForWork ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color:
                  auth.isOnlineForWork ? AppColors.primary : AppColors.textHint,
            ),
            onPressed: () => auth.setOnlineForWork(!auth.isOnlineForWork),
          ),
          IconButton(
            tooltip: 'Wallet',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => setState(() => _tab = 1),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        sizing: StackFit.expand,
        children: const [
          RiderDashboardTab(),
          RiderWalletTab(),
          RiderProfileHub(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _tab,
        height: 72,
        backgroundColor: Colors.transparent,
        color: AppColors.primary,
        animationDuration: const Duration(milliseconds: 380),
        animationCurve: Curves.easeOutCubic,
        onTap: (i) => setState(() => _tab = i),
        items: [
          _navItem(Icons.dashboard_rounded, 'Home', 0),
          _navItem(Icons.account_balance_wallet_rounded, 'Wallet', 1),
          _navItem(Icons.person_outline_rounded, 'Profile', 2),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_drawerCtrl.value > 0.01) _closeDrawer();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.backgroundLight,
                    AppColors.primaryLight.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: _kDrawerWidth,
              child: _RiderSideDrawer(
                key: _riderDrawerKey,
                tabIndex: _tab,
                auth: auth,
                onSelectTab: _goTab,
                onSignOut: () async {
                  _closeDrawer();
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _drawerCtrl,
            builder: (context, child) {
              return _animatedMainPanel(
                child ?? const SizedBox.shrink(),
                _drawerCtrl.value,
              );
            },
            child: _buildMainShell(auth),
          ),
          AnimatedBuilder(
            animation: _drawerCtrl,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_drawerCtrl.value);
              if (t < 0.001) return const SizedBox.shrink();
              return Positioned(
                left: _kDrawerWidth * t,
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeDrawer,
                  onHorizontalDragUpdate: (d) {
                    final w = MediaQuery.sizeOf(context).width;
                    _drawerCtrl.value =
                        (_drawerCtrl.value - d.delta.dx / (w * 0.85))
                            .clamp(0.0, 1.0);
                  },
                  onHorizontalDragEnd: (_) {
                    if (_drawerCtrl.value < 0.35) {
                      _closeDrawer();
                    } else {
                      _drawerCtrl.forward();
                    }
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.28 * t),
                          Colors.black.withValues(alpha: 0.06 * t),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final sel = _tab == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: Colors.white),
        if (!sel) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Styled side drawer — English copy, staggered entrance animations.
class _RiderSideDrawer extends StatefulWidget {
  const _RiderSideDrawer({
    super.key,
    required this.tabIndex,
    required this.auth,
    required this.onSelectTab,
    required this.onSignOut,
  });

  final int tabIndex;
  final AuthProvider auth;
  final void Function(int) onSelectTab;
  final VoidCallback onSignOut;

  @override
  State<_RiderSideDrawer> createState() => _RiderSideDrawerState();
}

class _RiderSideDrawerState extends State<_RiderSideDrawer>
    with SingleTickerProviderStateMixin {
  static const double _width = 300;

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 840),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void replayOpenAnimation() {
    if (!mounted) return;
    _ctrl
      ..reset()
      ..forward();
  }

  Animation<double> _stagger(int index, {double span = 0.38}) {
    final start = (0.06 + index * 0.058).clamp(0.0, 0.92);
    final end = (start + span).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<double> _earlyFade() {
    return CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );
  }

  Widget _slideIn(Widget child, Animation<double> anim) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(-0.12, 0), end: Offset.zero)
                .animate(anim),
        child: child,
      ),
    );
  }

  Widget _slideInIndex(Widget child, int index) =>
      _slideIn(child, _stagger(index));

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final auth = widget.auth;
    final tabIndex = widget.tabIndex;

    final avatarScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.42, curve: Curves.elasticOut),
      ),
    );

    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: SizedBox(
        width: _width,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(8, 0),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 168 + top,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.gradientPrimary,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -40,
                      top: -30,
                      child: FadeTransition(
                        opacity: _earlyFade(),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: FadeTransition(
                        opacity: _earlyFade(),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        // Drawer already has explicit height (168 + top). Using `top` again here
                        // can push content outside the header box on devices with large insets.
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _slideInIndex(
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Text(
                                        'Delivery partner',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: auth.isOnlineForWork
                                          ? Colors.green.withValues(alpha: 0.38)
                                          : Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          auth.isOnlineForWork
                                              ? Icons.circle
                                              : Icons.pause_circle_outline_rounded,
                                          size: auth.isOnlineForWork ? 8 : 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          auth.isOnlineForWork ? 'Online' : 'Offline',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.78,
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: Switch(
                                        value: auth.isOnlineForWork,
                                        activeThumbColor: Colors.white,
                                        activeTrackColor:
                                            Colors.green.withValues(alpha: 0.65),
                                        inactiveThumbColor: Colors.white,
                                        inactiveTrackColor:
                                            Colors.white.withValues(alpha: 0.28),
                                        onChanged: (v) => auth.setOnlineForWork(v),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              0,
                            ),
                            const SizedBox(height: 10),
                            _slideIn(
                              Row(
                                children: [
                                  ScaleTransition(
                                    scale: avatarScale,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.two_wheeler_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.appName,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.88),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          auth.userEmail ?? 'Rider',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Partner workspace',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.78),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              _stagger(1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _slideInIndex(_sectionLabel('Navigation'), 2),
                    const SizedBox(height: 8),
                    _slideInIndex(
                      _navRow(
                        context: context,
                        icon: Icons.dashboard_rounded,
                        title: 'Dashboard',
                        subtitle: 'Orders, routes & analytics',
                        selected: tabIndex == 0,
                        onTap: () => widget.onSelectTab(0),
                      ),
                      3,
                    ),
                    const SizedBox(height: 6),
                    _slideInIndex(
                      _navRow(
                        context: context,
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Wallet',
                        subtitle: 'Balance & top-up (demo)',
                        selected: tabIndex == 1,
                        onTap: () => widget.onSelectTab(1),
                      ),
                      4,
                    ),
                    const SizedBox(height: 6),
                    _slideInIndex(
                      _navRow(
                        context: context,
                        icon: Icons.person_rounded,
                        title: 'Profile',
                        subtitle: 'Account, legal & settings',
                        selected: tabIndex == 2,
                        onTap: () => widget.onSelectTab(2),
                      ),
                      5,
                    ),
                  ],
                ),
              ),
              _slideInIndex(
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.paddingOf(context).bottom + 12,
                  ),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onSignOut,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text(
                            'Sign out',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${AppStrings.appName} Rider · v1.0.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                9,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryLight.withValues(alpha: 0.65)
                : AppColors.backgroundLight.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.border.withValues(alpha: 0.65),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: selected
                        ? AppColors.gradientPrimary
                        : [
                            AppColors.textHint.withValues(alpha: 0.2),
                            AppColors.textHint.withValues(alpha: 0.12),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: selected
                    ? AppColors.primary
                    : AppColors.textHint.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

