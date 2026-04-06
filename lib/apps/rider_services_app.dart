import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/rider/rider_home_screen.dart';
import '../screens/service_worker/service_worker_home_screen.dart';
import 'common/app_providers.dart';
import 'common/role_login_screens.dart';

class RiderServicesApp extends StatelessWidget {
  const RiderServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: '${AppStrings.appName} Rider Services',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const _RiderServicesSplash(),
          AppRoutes.login: (_) => const _RiderServicesLoginHub(),
          AppRoutes.riderHome: (_) => const RiderHomeScreen(),
          AppRoutes.serviceWorkerHome: (_) => const ServiceWorkerHomeScreen(),
          '/login-rider': (_) => const RiderLoginScreen(),
          '/login-home-services': (_) => const HomeServicesLoginScreen(),
        },
      ),
    );
  }
}

class _RiderServicesSplash extends StatefulWidget {
  const _RiderServicesSplash();

  @override
  State<_RiderServicesSplash> createState() => _RiderServicesSplashState();
}

class _RiderServicesSplashState extends State<_RiderServicesSplash> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.checkAuthStatus();
    if (!mounted) return;

    if (!auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    if (auth.userType == UserType.rider) {
      Navigator.pushReplacementNamed(context, AppRoutes.riderHome);
      return;
    }
    if (auth.userType == UserType.serviceWorker) {
      Navigator.pushReplacementNamed(context, AppRoutes.serviceWorkerHome);
      return;
    }

    // Prevent cross-app session bleed.
    await auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
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

class _RiderServicesLoginHub extends StatelessWidget {
  const _RiderServicesLoginHub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider / Home Services')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            const Text(
              'Select your role to continue',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login-rider'),
                child: const Text('Login as Rider'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/login-home-services'),
                child: const Text('Login as Home Services'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

