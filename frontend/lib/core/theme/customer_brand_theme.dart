import 'package:flutter/material.dart';

/// Carries brand colors for customer UI (nav bar, gradients) alongside [ThemeData].
@immutable
class CustomerBrandColors extends ThemeExtension<CustomerBrandColors> {
  const CustomerBrandColors({
    required this.primary,
    required this.primaryLight,
    required this.headerGradient,
  });

  final Color primary;
  final Color primaryLight;
  final List<Color> headerGradient;

  @override
  CustomerBrandColors copyWith({
    Color? primary,
    Color? primaryLight,
    List<Color>? headerGradient,
  }) {
    return CustomerBrandColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      headerGradient: headerGradient ?? this.headerGradient,
    );
  }

  @override
  CustomerBrandColors lerp(ThemeExtension<CustomerBrandColors>? other, double t) {
    if (other is! CustomerBrandColors) return this;
    return CustomerBrandColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      headerGradient: headerGradient,
    );
  }
}

extension CustomerBrandContext on BuildContext {
  /// Brand colors from the active customer theme; falls back to purple if missing.
  CustomerBrandColors get customerBrand {
    final ext = Theme.of(this).extension<CustomerBrandColors>();
    if (ext != null) return ext;
    return const CustomerBrandColors(
      primary: Color(0xFF6C63FF),
      primaryLight: Color(0xFFEEEDFF),
      headerGradient: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
    );
  }
}

