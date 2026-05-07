import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Best-effort demo voiceover for investor walkthrough.
/// - Disabled by default; only used by the guided demo overlay.
/// - No network calls; uses device TTS.
class DemoVoice {
  DemoVoice._();

  static final FlutterTts _tts = FlutterTts();
  static bool _configured = false;
  static bool enabled = false;

  static Future<void> configureIfNeeded() async {
    if (_configured) return;
    _configured = true;

    // Do not block demo if a platform doesn’t support a setting.
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    try {
      // Keep it intelligible even on iOS simulator.
      await _tts.setSpeechRate(0.48);
    } catch (_) {}
    try {
      await _tts.setPitch(1.0);
    } catch (_) {}
    try {
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> speak(String title, String subtitle) async {
    if (!enabled) return;
    if (bool.fromEnvironment('FLUTTER_TEST')) return;
    await configureIfNeeded();

    final text = _compose(title, subtitle);
    if (text.trim().isEmpty) return;

    try {
      // If the next caption comes quickly, interrupt to keep narration in-sync.
      await _tts.stop();
    } catch (_) {}

    try {
      await _tts.speak(text);
    } catch (e, st) {
      if (kDebugMode) debugPrint('DemoVoice speak failed: $e\n$st');
    }
  }

  static String _compose(String title, String subtitle) {
    // Keep it short + natural for TTS.
    final t = title.trim();
    final s = subtitle.trim();
    if (t.isEmpty) return s;
    if (s.isEmpty) return t;
    return '$t. $s';
  }
}

