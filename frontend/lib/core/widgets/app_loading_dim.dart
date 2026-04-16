import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../constants/app_colors.dart';

/// Semi-transparent scrim + animated card spinner (use on top of a screen [Stack]).
class AppLoadingDim extends StatelessWidget {
  const AppLoadingDim({
    super.key,
    required this.visible,
    this.message,
  });

  final bool visible;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: visible
            ? Material(
                color: Colors.black.withValues(alpha: 0.28),
                child: Center(
                  child: _LoadingCard(message: message)
                      .animate()
                      .fadeIn(duration: 240.ms, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.94, 0.94),
                        end: const Offset(1, 1),
                        duration: 280.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 14,
      shadowColor: AppColors.primary.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget.fourRotatingDots(
              color: AppColors.primary,
              size: 52,
            ),
            if ((message ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                message!.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
