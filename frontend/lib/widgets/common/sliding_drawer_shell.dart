import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Exposes [SlidingDrawerShell]'s slide [Animation] to descendants (e.g. menu icon).
class SlidingDrawerScope extends InheritedNotifier<Animation<double>> {
  const SlidingDrawerScope({
    super.key,
    required Animation<double> animation,
    required super.child,
  }) : super(notifier: animation);

  static Animation<double>? maybeSlideOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SlidingDrawerScope>()
        ?.notifier;
  }
}

/// Push drawer: main content slides right while the menu panel sits
/// on the left (push / reveal), not the default [Drawer] overlay.
class SlidingDrawerShell extends StatefulWidget {
  const SlidingDrawerShell({
    super.key,
    required this.drawer,
    required this.child,
    this.drawerWidthFraction = 0.78,
    this.maxDrawerWidth = 300,
    this.duration = const Duration(milliseconds: 320),
  });

  /// Convenience accessor to control the nearest shell.
  static SlidingDrawerShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<SlidingDrawerShellState>();

  final Widget drawer;
  final Widget child;

  /// Drawer width = min(maxDrawerWidth, screenWidth * drawerWidthFraction).
  final double drawerWidthFraction;
  final double maxDrawerWidth;
  final Duration duration;

  @override
  SlidingDrawerShellState createState() => SlidingDrawerShellState();
}

class SlidingDrawerShellState extends State<SlidingDrawerShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _slide = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isOpen => _controller.value > 0.01;

  void openDrawer() {
    _controller.forward();
  }

  void closeDrawer() {
    _controller.reverse();
  }

  void toggleDrawer() {
    if (isOpen) {
      closeDrawer();
    } else {
      openDrawer();
    }
  }

  double _drawerWidth(double screenWidth) {
    return math.min(
      widget.maxDrawerWidth,
      screenWidth * widget.drawerWidthFraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final drawerW = _drawerWidth(width);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isOpen) {
          closeDrawer();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, _) {
          final t = _slide.value;
          final offset = drawerW * t;

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: drawerW,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  child: widget.drawer,
                ),
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(offset, 0),
                  child: Transform.scale(
                    scale: 1 - 0.04 * t,
                    alignment: Alignment.center,
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      elevation: 8 * t,
                      shadowColor: Colors.black.withValues(alpha: 0.35),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14 * t),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            SlidingDrawerScope(
                              animation: _slide,
                              child: widget.child,
                            ),
                            if (t > 0.01)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: closeDrawer,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

