import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';

/// Small helpers to keep async UI code safe (timeouts + friendly errors).
class AsyncGuard {
  static Future<T> withTimeout<T>(
    Future<T> future, {
    Duration timeout = const Duration(seconds: 15),
    String? timeoutMessage,
  }) {
    return future.timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(timeoutMessage ?? 'Request timed out', timeout);
      },
    );
  }

  static String friendlyMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'Server response slow hai. Thori dair baad dobara try karein.';
    }
    return 'Kuch ghalat ho gaya. Please dobara try karein.';
  }

  /// Technical lines for expandable “detail” in snackbars (API errors, debug dumps).
  static String? optionalDetail(Object error) {
    if (error is ApiException) {
      // Parsed server JSON message — no Dio dump needed.
      if (error.cause == null) {
        return null;
      }
      final buf = StringBuffer();
      if (error.statusCode != null) {
        buf.writeln('HTTP ${error.statusCode}');
      }
      buf.writeln(error.cause.toString());
      final s = buf.toString().trim();
      if (s.isNotEmpty) return s;
      if (kDebugMode && error.message.length > 120) {
        return error.message;
      }
      return null;
    }
    if (error is TimeoutException) {
      return error.toString();
    }
    if (kDebugMode) {
      return error.toString();
    }
    return null;
  }
}

