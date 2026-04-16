import 'dart:async';
import 'dart:io' show Platform;

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/dev_log.dart';
import '../../models/service_provider_profile.dart';
import '../../providers/service_provider_directory_provider.dart';

/// Background location updater for service providers.
///
/// Reality:
/// - Android: periodic background fetch is fairly reliable (still OS-dependent).
/// - iOS: best-effort only (system decides frequency). For always-on tracking,
///   we’d need a dedicated background location mode + stronger policies.
class ProviderBackgroundLocation {
  ProviderBackgroundLocation._();

  static const String _kPrefsEnabled = 'provider_bg_location_enabled_v1';
  static const String _kPrefsLastLog = 'provider_bg_location_last_log_v1';
  static bool _initialized = false;
  static bool _available = false;

  /// Call once during app startup.
  static Future<void> init({
    required ServiceProviderDirectoryProvider directory,
  }) async {
    if (_initialized) return;
    _initialized = true;

    devLog(
      '[BG] init called os=${Platform.operatingSystem} '
      'android=${Platform.isAndroid} ios=${Platform.isIOS} web=$kIsWeb',
    );

    // background_fetch is only implemented on Android/iOS.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      devLog('[BG] background_fetch not supported on this platform');
      return;
    }

    // iOS sometimes logs MissingPluginException if called too early after hot-restart.
    // A short delay reduces noisy startup logs.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Configure fetch.
    try {
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15, // minutes (platform clamps)
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ),
        (String taskId) async {
          try {
            await _tick(directory);
          } catch (e, st) {
            devLog('BG location tick error', e, st);
          } finally {
            BackgroundFetch.finish(taskId);
          }
        },
        (String taskId) async {
          BackgroundFetch.finish(taskId);
        },
      );
      _available = true;
      devLog('[BG] configured OK');
    } catch (e) {
      // Happens if running on an unsupported platform, plugin registration failed,
      // or the plugin throws (some versions assume different exception shapes).
      devLog('[BG] background_fetch configure failed', e);
      _available = false;
      return;
    }

    // Headless task (Android).
    try {
      BackgroundFetch.registerHeadlessTask(_headlessTask);
      devLog('[BG] registerHeadlessTask OK');
    } catch (e) {
      devLog('[BG] registerHeadlessTask failed', e);
      _available = false;
      return;
    }

    // Ensure state matches stored toggle.
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kPrefsEnabled) ?? false;
    try {
      if (enabled) {
        await BackgroundFetch.start();
        devLog('[BG] started (from prefs)');
      } else {
        await BackgroundFetch.stop();
        devLog('[BG] stopped (from prefs)');
      }
    } catch (e) {
      devLog('[BG] start/stop failed', e);
      _available = false;
      return;
    }
  }

  /// Enable/disable background updates. Call when provider toggles Online/Offline.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsEnabled, enabled);
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (!_available) {
      devLog('[BG] setEnabled($enabled) ignored: not available');
      return;
    }
    try {
      if (enabled) {
        await BackgroundFetch.start();
        devLog('[BG] started (toggle)');
      } else {
        await BackgroundFetch.stop();
        devLog('[BG] stopped (toggle)');
      }
    } catch (e) {
      devLog('[BG] start/stop failed', e);
    }
  }

  static Future<void> _tick(ServiceProviderDirectoryProvider directory) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kPrefsEnabled) ?? false;
    if (!enabled) return;

    // We store who the active provider is in prefs (set on signup/login).
    final providerId = prefs.getString('active_provider_id');
    if (providerId == null || providerId.trim().isEmpty) return;

    devLog('[BG] tick start provider=$providerId');

    // We only update if the provider exists in the local directory.
    final current = directory.providers
        .where((p) => p.id == providerId.trim())
        .cast<ServiceProviderProfile?>()
        .firstWhere((p) => p != null, orElse: () => null);
    if (current == null) return;

    final pos = await _getPositionSafely();
    if (pos == null) {
      devLog('[BG] no position (perm/service off?) provider=$providerId');
      return;
    }

    devLog(
      '[BG] pos provider=$providerId lat=${pos.latitude} lng=${pos.longitude} '
      'acc=${pos.accuracy.toStringAsFixed(1)}m at=${DateTime.now().toIso8601String()}',
    );

    // Persist last log so it can be shown in UI if needed.
    try {
      await prefs.setString(
        _kPrefsLastLog,
        'provider=$providerId lat=${pos.latitude} lng=${pos.longitude} '
        'acc=${pos.accuracy.toStringAsFixed(1)}m at=${DateTime.now().toIso8601String()}',
      );
    } catch (_) {}

    directory.upsert(
      ServiceProviderProfile(
        id: current.id,
        name: current.name,
        phone: current.phone,
        profession: current.profession,
        nic: current.nic,
        imagePath: current.imagePath,
        plan: current.plan,
        isOnline: true,
        areaLabel: current.areaLabel,
        lat: pos.latitude,
        lng: pos.longitude,
        updatedAt: DateTime.now(),
        createdAt: current.createdAt,
      ),
    );

    devLog('[BG] upserted provider=$providerId');
  }

  static Future<String?> getLastLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kPrefsLastLog);
    } catch (_) {
      return null;
    }
  }

  static Future<Position?> _getPositionSafely() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }

    // Low power is fine for “near me” radius.
    const settings = LocationSettings(
      accuracy: LocationAccuracy.low,
      timeLimit: Duration(seconds: 12),
    );
    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  /// Headless task entry (Android only). We can't access providers here in a
  /// reliable way without building a full headless isolate wiring.
  /// For now, it just finishes; periodic ticks run while the app has been opened at least once.
  static Future<void> _headlessTask(HeadlessTask task) async {
    BackgroundFetch.finish(task.taskId);
  }
}

