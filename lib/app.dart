import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/gym_management_provider.dart';
import 'providers/job_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/business_selection/business_selection_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/products/add_product_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/service_worker/service_worker_home_screen.dart';
import 'screens/rider/rider_home_screen.dart';
import 'screens/splash/splash_screen.dart';

class BizLabelApp extends StatelessWidget {
  const BizLabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => GymManagementProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.businessSelection: (_) => const BusinessSelectionScreen(),
          AppRoutes.dashboard: (_) => const DashboardScreen(),
          AppRoutes.products: (_) => const ProductsScreen(),
          AppRoutes.addProduct: (_) => const AddProductScreen(),
          AppRoutes.orders: (_) => const OrdersScreen(),
          AppRoutes.customers: (_) => const CustomersScreen(),
          AppRoutes.notifications: (_) => const NotificationsScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.payment: (_) => const PaymentScreen(),
          AppRoutes.customerHome: (_) => const CustomerHomeScreen(),
          AppRoutes.serviceWorkerHome: (_) => const ServiceWorkerHomeScreen(),
          AppRoutes.riderHome: (_) => const RiderHomeScreen(),
        },
      ),
    );
  }
}

