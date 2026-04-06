import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/rider/rider_home_screen.dart';
import 'common/app_providers.dart';
import 'common/role_login_screens.dart';
import 'common/role_splash_screen.dart';

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: '${AppStrings.appName} Rider',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const RoleSplashScreen(
                requiredRole: UserType.rider,
                authenticatedRoute: AppRoutes.riderHome,
              ),
          AppRoutes.login: (_) => const RiderLoginScreen(),
          AppRoutes.riderHome: (_) => const RiderHomeScreen(),
        },
      ),
    );
  }
}

