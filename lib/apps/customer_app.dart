import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../screens/customer/customer_home_screen.dart';
import 'common/app_providers.dart';
import 'common/role_login_screens.dart';
import 'common/role_splash_screen.dart';
import '../providers/auth_provider.dart';

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: '${AppStrings.appName} Customer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const RoleSplashScreen(
                requiredRole: UserType.customer,
                authenticatedRoute: AppRoutes.customerHome,
              ),
          AppRoutes.login: (_) => const CustomerLoginScreen(),
          AppRoutes.customerHome: (_) => const CustomerHomeScreen(),
        },
      ),
    );
  }
}

