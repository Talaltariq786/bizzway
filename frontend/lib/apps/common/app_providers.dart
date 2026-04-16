import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_home_ui_notifier.dart';
import '../../providers/customer_profile_notifier.dart';
import '../../providers/customer_marketplace_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/customer_preferences_provider.dart';
import '../../providers/gym_management_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/near_me_ui_notifier.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/rider_team_provider.dart';
import '../../providers/theme_provider.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

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
        ChangeNotifierProvider(create: (_) => NearMeUiNotifier()),
        ChangeNotifierProvider(create: (_) => CustomerHomeUiNotifier()),
        ChangeNotifierProvider(create: (_) => CustomerProfileNotifier()),
        ChangeNotifierProvider(create: (_) => CustomerMarketplaceProvider()),
      ],
      child: child,
    );
  }
}

