import 'package:flutter/material.dart';

/// Smooth animated page transition widget for IndexedStack
class AnimatedPageTransition extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedPageTransition({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedPageTransition> createState() => _AnimatedPageTransitionState();
}

class _AnimatedPageTransitionState extends State<AnimatedPageTransition>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _setupAnimations();
    _controller.forward();
  }

  void _setupAnimations() {
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );
  }

  @override
  void didUpdateWidget(AnimatedPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(
          index: widget.index,
          children: widget.children,
        ),
      ),
    );
  }
}
