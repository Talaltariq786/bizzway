import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/business_selection/business_selection_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/products/add_product_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/legal/terms_and_backend_handoff_screen.dart';
import '../screens/profile/about_bizzway_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/help_support_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/store_qr_screen.dart';
import '../screens/riders/rider_team_screen.dart';
import 'common/role_login_screens.dart';
import 'common/app_providers.dart';
import 'common/role_splash_screen.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class BusinessApp extends StatelessWidget {
  const BusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: Builder(
        builder: (context) => MaterialApp(
          title: '${AppStrings.appName} Business',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightThemeWithAccent(
            context.watch<ThemeProvider>().accentColor,
          ),
          darkTheme: AppTheme.darkThemeWithAccent(
            context.watch<ThemeProvider>().accentColor,
          ),
          themeMode: context.watch<ThemeProvider>().mode,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const RoleSplashScreen(
                  requiredRole: UserType.businessOwner,
                  authenticatedRoute: AppRoutes.dashboard,
                ),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.businessSelection: (_) => const BusinessSelectionScreen(),
            AppRoutes.dashboard: (_) => const DashboardScreen(),
            AppRoutes.products: (_) => const ProductsScreen(),
            AppRoutes.addProduct: (_) => const AddProductScreen(),
            AppRoutes.orders: (_) => const OrdersScreen(),
            AppRoutes.customers: (_) => const CustomersScreen(),
            AppRoutes.notifications: (_) => const NotificationsScreen(),
            AppRoutes.profile: (_) => const ProfileScreen(),
            AppRoutes.storeQr: (_) => const StoreQrScreen(),
            AppRoutes.termsAndConditions: (_) =>
                const TermsAndBackendHandoffScreen(),
            AppRoutes.helpSupport: (_) => const HelpSupportScreen(),
            AppRoutes.changePassword: (_) => const ChangePasswordScreen(),
            AppRoutes.aboutBizzway: (_) => const AboutBizzwayScreen(),
            AppRoutes.payment: (_) => const PaymentScreen(),
            AppRoutes.riderTeam: (_) => const RiderTeamScreen(),
            AppRoutes.riderLogin: (_) => const RiderLoginScreen(),
          },
        ),
      ),
    );
  }
}

