import 'package:flutter/material.dart';

/// Tailwind-derived palette used across the app.
///
/// Base shades are `const` (so they can be used in const widgets). For the
/// "/10", "/20" opacity variants Tailwind uses (e.g. `bg-rose-500/10`), call
/// [a] at the use site, e.g. `AppColors.a(AppColors.rose500, 0.1)`.
class AppColors {
  AppColors._(); // never instantiated; just a namespace for constants

  // Neutral "zinc" scale (backgrounds, text, borders)
  static const zinc950 = Color(0xFF09090B);
  static const zinc900 = Color(0xFF18181B);
  static const zinc800 = Color(0xFF27272A);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc600 = Color(0xFF52525B);
  static const zinc500 = Color(0xFF71717A);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc100 = Color(0xFFF4F4F5);

  // Accent colours
  static const cyan500 = Color(0xFF06B6D4);
  static const cyan400 = Color(0xFF22D3EE);
  static const cyan300 = Color(0xFF67E8F9);
  static const rose600 = Color(0xFFE11D48);
  static const rose500 = Color(0xFFF43F5E);
  static const rose400 = Color(0xFFFB7185);
  static const rose300 = Color(0xFFFDA4AF);
  static const amber500 = Color(0xFFF59E0B);
  static const amber400 = Color(0xFFFBBF24);
  static const emerald500 = Color(0xFF10B981);
  static const emerald400 = Color(0xFF34D399);
  static const violet500 = Color(0xFF8B5CF6);
  static const violet400 = Color(0xFFA78BFA);
  static const sky400 = Color(0xFF38BDF8);
  static const orange400 = Color(0xFFFB923C);

  /// Returns [c] with the given [alpha] (0..1) — the equivalent of Tailwind's
  /// `/NN` opacity suffix.
  static Color a(Color c, double alpha) => c.withValues(alpha: alpha);
}
