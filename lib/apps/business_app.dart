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
import '../screens/profile/profile_screen.dart';
import 'common/app_providers.dart';
import 'common/role_login_screens.dart';
import 'common/role_splash_screen.dart';

class BusinessApp extends StatelessWidget {
  const BusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: '${AppStrings.appName} Business',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const RoleSplashScreen(
                requiredRole: UserType.businessOwner,
                authenticatedRoute: AppRoutes.dashboard,
              ),
          AppRoutes.login: (_) => const BusinessLoginScreen(),
          AppRoutes.businessSelection: (_) => const BusinessSelectionScreen(),
          AppRoutes.dashboard: (_) => const DashboardScreen(),
          AppRoutes.products: (_) => const ProductsScreen(),
          AppRoutes.addProduct: (_) => const AddProductScreen(),
          AppRoutes.orders: (_) => const OrdersScreen(),
          AppRoutes.customers: (_) => const CustomersScreen(),
          AppRoutes.notifications: (_) => const NotificationsScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.payment: (_) => const PaymentScreen(),
        },
      ),
    );
  }
}

