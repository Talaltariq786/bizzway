import 'package:flutter/material.dart';

/// Clips the drawer so when [progress] is 0 nothing shows (no “peek” behind main UI).
class _DrawerRevealClipper extends CustomClipper<Rect> {
  _DrawerRevealClipper({required this.visibleWidth});
  final double visibleWidth;

  @override
  Rect getClip(Size size) {
    final w = visibleWidth.clamp(0.0, size.width);
    return Rect.fromLTWH(0, 0, w, size.height);
  }

  @override
  bool shouldReclip(covariant _DrawerRevealClipper old) =>
      old.visibleWidth != visibleWidth;
}

/// Pushes [body] to the right when opening the drawer.
class SlidingPushDrawerLayout extends StatelessWidget {
  const SlidingPushDrawerLayout({
    super.key,
    required this.progress,
    required this.drawerWidth,
    required this.drawer,
    required this.body,
    this.onScrimTap,
    this.scrimOpacity = 0.38,
  });

  /// 0 = closed, 1 = fully open.
  final double progress;
  final double drawerWidth;
  final Widget drawer;
  final Widget body;
  final VoidCallback? onScrimTap;
  final double scrimOpacity;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final safeTop = MediaQuery.paddingOf(context).top;
    const headerReserve = 64.0;
    final revealW = drawerWidth * t;

    final surface = Theme.of(context).colorScheme.surface;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: drawerWidth,
          child: ClipRect(
            clipper: _DrawerRevealClipper(visibleWidth: revealW),
            child: drawer,
          ),
        ),
        Transform.translate(
          offset: Offset(drawerWidth * t, 0),
          child: Material(
            color: surface,
            child: body,
          ),
        ),
        if (t > 0.002 && onScrimTap != null)
          Positioned(
            left: drawerWidth * t,
            right: 0,
            top: safeTop + headerReserve,
            bottom: 0,
            child: GestureDetector(
              onTap: onScrimTap,
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: scrimOpacity * t),
              ),
            ),
          ),
      ],
    );
  }
}

