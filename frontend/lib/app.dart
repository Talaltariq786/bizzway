import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/customer_marketplace_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/customer_preferences_provider.dart';
import 'providers/gym_management_provider.dart';
import 'providers/job_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/api_catalog_provider.dart';
import 'providers/rider_team_provider.dart';
import 'providers/service_provider_directory_provider.dart';
import 'providers/theme_provider.dart';
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
import 'screens/profile/store_qr_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/customer/customer_settings_screen.dart';
import 'screens/service_worker/service_worker_home_screen.dart';
import 'screens/service_worker/service_worker_live_map_screen.dart';
import 'screens/service_worker/scrap_rates_editor_screen.dart';
import 'screens/rider/rider_home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/riders/rider_team_screen.dart';
import 'screens/legal/terms_and_backend_handoff_screen.dart';
import 'screens/profile/help_support_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/profile/about_bizzway_screen.dart';
import 'apps/common/role_login_screens.dart';
import 'core/services/provider_background_location.dart';

class BizLabelApp extends StatelessWidget {
  const BizLabelApp({super.key});

  static bool _bgInitScheduled = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => CustomerPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => RiderTeamProvider()),
        ChangeNotifierProvider(create: (_) => GymManagementProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProviderDirectoryProvider()),
        ChangeNotifierProvider(create: (_) => ApiCatalogProvider()),
        ChangeNotifierProvider(create: (_) => CustomerMarketplaceProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Init background location (best-effort). Safe to call multiple times.
          if (!_bgInitScheduled) {
            _bgInitScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future<void>.delayed(const Duration(milliseconds: 800), () {
                if (!context.mounted) return;
                ProviderBackgroundLocation.init(
                  directory: context.read<ServiceProviderDirectoryProvider>(),
                );
              });
            });
          }

          return MaterialApp(
            title: AppStrings.appName,
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
              AppRoutes.storeQr: (_) => const StoreQrScreen(),
              AppRoutes.payment: (_) => const PaymentScreen(),
              AppRoutes.customerHome: (_) => const CustomerHomeScreen(),
              AppRoutes.customerSettings: (_) => const CustomerSettingsScreen(),
              AppRoutes.serviceWorkerHome: (_) =>
                  const ServiceWorkerHomeScreen(),
              AppRoutes.serviceWorkerLiveMap: (_) =>
                  const ServiceWorkerLiveMapScreen(),
              AppRoutes.scrapRatesEditor: (_) =>
                  const ScrapRatesEditorScreen(),
              AppRoutes.riderHome: (_) => const RiderHomeScreen(),
              AppRoutes.riderLogin: (_) => const RiderLoginScreen(),
              AppRoutes.riderTeam: (_) => const RiderTeamScreen(),
              AppRoutes.termsAndConditions: (_) =>
                  const TermsAndBackendHandoffScreen(),
              AppRoutes.helpSupport: (_) => const HelpSupportScreen(),
              AppRoutes.changePassword: (_) => const ChangePasswordScreen(),
              AppRoutes.aboutBizzway: (_) => const AboutBizzwayScreen(),
            },
          );
        },
      ),
    );
  }
}

