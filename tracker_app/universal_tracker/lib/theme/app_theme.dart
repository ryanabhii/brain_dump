import 'package:flutter/material.dart';
import 'colors.dart';

/// Builds the dark theme that matches the prototype's look:
/// near-black "zinc" background with cyan as the primary accent.
ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.zinc950,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.cyan500,
      surface: AppColors.zinc950,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.zinc100,
      displayColor: AppColors.zinc100,
    ),
  );
}
