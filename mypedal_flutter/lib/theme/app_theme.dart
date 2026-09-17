
import 'package:flutter/material.dart';

/// Color palette used across the MyPedal app.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color primary = Color(0xFF00FFCC);
  static const Color secondary = Color(0xFF00BFFF);

  static const Color pedalTop = Color(0xFF2C2C2C);
  static const Color pedalBottom = Color(0xFF121212);
  static const Color pedalPressedTop = Color(0xFF1A1A1A);
  static const Color pedalPressedBottom = Color(0xFF0A0A0A);

  static const Color searching = Colors.orange;
}

/// Builds the global dark theme for the app.
ThemeData buildAppTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
  );
}
