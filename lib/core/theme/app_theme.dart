import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static final ThemeData dark = _build(
        brightness: Brightness.dark,
        scaffold: AppColors.black,
        surface: AppColors.surface,
        onSurface: AppColors.mist,
        title: AppColors.white,
        body: AppColors.mist,
        muted: AppColors.muted,
        hairline: AppColors.hairline,
        overlay: SystemUiOverlayStyle.light,
      );

  static final ThemeData light = _build(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF3F5FA),
        surface: Colors.white,
        onSurface: const Color(0xFF1E2A44),
        title: const Color(0xFF0B1428),
        body: const Color(0xFF1E2A44),
        muted: const Color(0xFF4E5D78),
        hairline: const Color(0xFFD8DEEA),
        overlay: SystemUiOverlayStyle.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color title,
    required Color body,
    required Color muted,
    required Color hairline,
    required SystemUiOverlayStyle overlay,
  }) {
    final display = GoogleFonts.frauncesTextTheme();
    final bodyTheme = GoogleFonts.soraTextTheme();

    final textTheme = bodyTheme
        .copyWith(
          displayLarge: display.displayLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
            color: title,
          ),
          displayMedium: display.displayMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: title,
          ),
          displaySmall: display.displaySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: title,
          ),
          headlineLarge: display.headlineLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: title,
          ),
          headlineMedium: display.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: title,
          ),
          headlineSmall: display.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: title,
          ),
          titleLarge: bodyTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: title,
          ),
          titleMedium: bodyTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: title,
          ),
          bodyLarge: bodyTheme.bodyLarge?.copyWith(
            height: 1.55,
            color: body,
          ),
          bodyMedium: bodyTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: muted,
          ),
          labelLarge: bodyTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: title,
          ),
        )
        .apply(bodyColor: body, displayColor: title);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.brandBlue,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        error: const Color(0xFFB3261E),
        onError: AppColors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      textTheme: textTheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay,
        titleTextStyle: GoogleFonts.sora(
          color: title,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        iconTheme: IconThemeData(color: title),
      ),
      iconTheme: IconThemeData(color: title),
      listTileTheme: ListTileThemeData(
        iconColor: title,
        textColor: title,
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandBlueSoft, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.surfaceHigh
            : const Color(0xFF0B1428),
        contentTextStyle: GoogleFonts.sora(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
