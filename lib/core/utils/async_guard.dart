import 'dart:async';

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
    if (error is TimeoutException) {
      return 'Server response slow hai. Thori dair baad dobara try karein.';
    }
    return 'Kuch ghalat ho gaya. Please dobara try karein.';
  }
}

