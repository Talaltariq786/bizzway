import 'package:flutter/material.dart';

/// Smooth wave at the bottom of the auth header for a polished hand-off to the body.
class AuthHeaderWaveClipper extends CustomClipper<Path> {
  const AuthHeaderWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 8,
      size.width * 0.5,
      size.height - 22,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 36,
      size.width,
      size.height - 18,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
