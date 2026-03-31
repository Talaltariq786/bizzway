import 'package:flutter/material.dart';

/// Central place to control imagery.
///
/// Current app uses random external images (loremflickr) which are not
/// Pakistan-specific and may fail on slow/blocked networks.
/// We default to placeholders; later you can plug Pakistani asset images here.
class AppMedia {
  AppMedia._();

  /// Turn this on only if you intentionally want external stock images.
  static const bool useExternalStockImages = true;

  static LinearGradient gradientForType(Color brand) => LinearGradient(
        colors: [
          brand.withValues(alpha: 0.25),
          brand.withValues(alpha: 0.06),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

