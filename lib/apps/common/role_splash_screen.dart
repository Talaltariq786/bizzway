import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';

class RoleSplashScreen extends StatefulWidget {
  final UserType requiredRole;

  /// Where to go after successful auth + role match.
  final String authenticatedRoute;

  /// If role mismatch, go here after logout.
  final String unauthenticatedRoute;

  const RoleSplashScreen({
    super.key,
    required this.requiredRole,
    required this.authenticatedRoute,
    this.unauthenticatedRoute = AppRoutes.login,
  });

  @override
  State<RoleSplashScreen> createState() => _RoleSplashScreenState();
}

class _RoleSplashScreenState extends State<RoleSplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Small delay so splash renders instantly.
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.checkAuthStatus();
    if (!mounted) return;

    if (!auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, widget.unauthenticatedRoute);
      return;
    }

    if (auth.userType != widget.requiredRole) {
      // Avoid cross-app session bleed (same SharedPreferences keys).
      await auth.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.unauthenticatedRoute);
      return;
    }

    // Business owner needs selected business before dashboard.
    if (widget.requiredRole == UserType.businessOwner) {
      final business = context.read<BusinessProvider>();
      await business.loadBusiness();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        business.selectedBusiness == null
            ? AppRoutes.businessSelection
            : AppRoutes.dashboard,
      );
      return;
    }

    Navigator.pushReplacementNamed(context, widget.authenticatedRoute);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

