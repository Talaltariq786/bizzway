import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppAssetImage extends StatelessWidget {
  final String businessTypeId;
  final String seed;
  final String? itemName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppAssetImage({
    super.key,
    required this.businessTypeId,
    required this.seed,
    this.itemName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  static String assetFor({
    required String businessTypeId,
    String? itemName,
  }) {
    final n = (itemName ?? '').toLowerCase();

    if (businessTypeId == 'salon' || businessTypeId == 'beauty') {
      return 'assets/images/salon_haircut.svg';
    }
    if (businessTypeId == 'grocery' || businessTypeId == 'pharmacy' || businessTypeId == 'others') {
      return 'assets/images/grocery_bag.svg';
    }
    if (businessTypeId == 'restaurant' || businessTypeId == 'cafe') {
      if (n.contains('biryani') || n.contains('rice')) return 'assets/images/food_biryani.svg';
      if (n.contains('karahi') || n.contains('tikka') || n.contains('chicken')) return 'assets/images/food_karahi.svg';
      if (n.contains('burger')) return 'assets/images/food_burger.svg';
      return 'assets/images/food_karahi.svg';
    }

    // Generic fallback
    return 'assets/images/grocery_bag.svg';
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(businessTypeId: businessTypeId, itemName: itemName);

    final child = SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

