import 'package:flutter/material.dart';

Theme wrapDialogWithTheme(
  BuildContext context, {
  required Color accentColor,
  required Widget child,
}) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: accentColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
        ),
      ),
    ),
    child: child,
  );
}
