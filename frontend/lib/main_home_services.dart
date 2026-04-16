import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apps/home_services_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('_pressedKeys.containsKey')) return;
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('_pressedKeys.containsKey')) return true;
    return false;
  };
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HomeServicesApp());
}

