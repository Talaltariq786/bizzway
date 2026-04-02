import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color primaryLight = Color(0xFFEEEDFF);
  static const Color accent = Color(0xFFFF6584);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  static const Color backgroundLight = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);

  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE0E0E0);

  static const Color pending = Color(0xFFFFF3CD);
  static const Color pendingText = Color(0xFF856404);
  static const Color completed = Color(0xFFD1FAE5);
  static const Color completedText = Color(0xFF065F46);
  static const Color cancelled = Color(0xFFFEE2E2);
  static const Color cancelledText = Color(0xFF991B1B);

  static const List<Color> gradientPrimary = [
    Color(0xFF6C63FF),
    Color(0xFF9B59B6),
  ];

  static const List<Color> gradientCard = [
    Color(0xFF6C63FF),
    Color(0xFF48C9B0),
  ];

  static List<Color> gradientFrom(Color seed) => [
    Color.lerp(seed, Colors.black, 0.16) ?? seed,
    Color.lerp(seed, Colors.white, 0.08) ?? seed,
  ];
}
