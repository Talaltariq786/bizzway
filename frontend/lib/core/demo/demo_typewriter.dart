import 'package:flutter/material.dart';

/// Simulates a user typing into a field (for investor / screen-record demos).
class DemoTypewriter {
  DemoTypewriter._();

  static Future<void> fill(
    TextEditingController controller,
    String text, {
    Duration perChar = const Duration(milliseconds: 42),
    bool Function()? shouldAbort,
  }) async {
    controller.clear();
    for (var i = 0; i < text.length; i++) {
      if (shouldAbort?.call() == true) return;
      controller.text = text.substring(0, i + 1);
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      await Future<void>.delayed(perChar);
    }
  }

  static void replace(
    TextEditingController controller,
    String text,
  ) {
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  }
}
