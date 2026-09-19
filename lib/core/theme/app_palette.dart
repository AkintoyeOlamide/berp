import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware surface/text colors for destination screens.
class AppPalette {
  const AppPalette._(this.isDark);

  factory AppPalette.of(BuildContext context) {
    return AppPalette._(Theme.of(context).brightness == Brightness.dark);
  }

  final bool isDark;

  Color get scaffold =>
      isDark ? AppColors.black : const Color(0xFFF3F5FA);

  Color get title =>
      isDark ? AppColors.white : const Color(0xFF0B1428);

  Color get mist =>
      isDark ? AppColors.mist : const Color(0xFF1E2A44);

  Color get body =>
      isDark ? AppColors.muted : const Color(0xFF4E5D78);

  Color get mutedDark =>
      isDark ? AppColors.mutedDark : const Color(0xFF73819A);

  Color get eyebrow =>
      isDark ? AppColors.brandBlueSoft : AppColors.brandBlue;

  Color get card => isDark
      ? const Color(0xCC141C30)
      : const Color(0xF2FFFFFF);

  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF1A2F8C).withValues(alpha: 0.1);

  Color get hairline =>
      isDark ? AppColors.hairline : const Color(0xFFD8DEEA);

  Color get chipFill => isDark
      ? AppColors.surface.withValues(alpha: 0.88)
      : Colors.white.withValues(alpha: 0.96);

  Color get mapScrimTop => isDark
      ? const Color(0xC2070A12)
      : const Color(0xD9F3F5FA);

  Color get mapScrimMid => isDark
      ? const Color(0xE0070A12)
      : const Color(0xEDF3F5FA);

  Color get mapScrimBottom => isDark
      ? const Color(0xF5070A12)
      : const Color(0xF8F3F5FA);

  Color get iconOnBrand => AppColors.white;

  Color get accentRail =>
      isDark ? AppColors.brandBlueSoft : AppColors.brandBlue;

  LinearGradient get pageWash => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1430),
            Color(0xFF070A12),
            Color(0xFF0A1020),
          ],
          stops: [0.0, 0.55, 1.0],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEF2FA),
            Color(0xFFF3F5FA),
            Color(0xFFE8EDF7),
          ],
        );
}
