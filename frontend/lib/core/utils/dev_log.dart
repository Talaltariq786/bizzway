import 'package:flutter/foundation.dart';

/// Debug builds only — **release mein console par kuch nahi** (no error spam).
void devLog(String message, [Object? error, StackTrace? stackTrace]) {
  if (!kDebugMode) return;
  final b = StringBuffer(message);
  if (error != null) {
    b.writeln();
    b.write(error);
  }
  if (stackTrace != null) {
    b.writeln();
    b.write(stackTrace);
  }
  debugPrint(b.toString());
}
