import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'app.dart';
import 'core/config/api_config.dart';
import 'firebase_options.dart';

/// Reduces native map crashes on some Android devices (OEM / GPU quirks).
void _configureGoogleMapsAndroid() {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final GoogleMapsFlutterPlatform impl = GoogleMapsFlutterPlatform.instance;
  if (impl is GoogleMapsFlutterAndroid) {
    impl.useAndroidViewSurface = true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureGoogleMapsAndroid();
  await ApiConfig.initFromPrefs();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Print tokens for debugging push setup (safe if null on simulator).
  try {
    final settings = await FirebaseMessaging.instance.requestPermission();
    debugPrint('PUSH_PERMISSION=${settings.authorizationStatus.name}');

    final apns = await FirebaseMessaging.instance.getAPNSToken();
    debugPrint('APNS_TOKEN=${apns ?? "null"}');

    final fcm = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM_TOKEN=${fcm ?? "null"}');
  } catch (e) {
    debugPrint('PUSH_TOKEN_ERROR=$e');
  }

  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('_pressedKeys.containsKey')) return;
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('_pressedKeys.containsKey')) return true;
    return false;
  };
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BizLabelApp());
}
