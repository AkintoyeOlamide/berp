import 'package:flutter/material.dart';

/// BERP brand colors — charcoal surfaces with restrained accents.
abstract final class AppColors {
  static const Color brandBlue = Color(0xFF3A4A8C);
  static const Color brandBlueDeep = Color(0xFF1C2238);
  static const Color brandBlueGlow = Color(0xFF6B8CFF);
  static const Color brandBlueSoft = Color(0xFF7A90C8);

  /// Calm accent (used sparingly).
  static const Color secondary = Color(0xFF6B8CFF);
  static const Color cyan = secondary;
  static const Color orange = Color(0xFFF69306);
  static const Color green = Color(0xFF75BD42);

  static const Color black = Color(0xFF0A0A0A);
  static const Color blackElevated = Color(0xFF121212);
  static const Color surface = Color(0xFF161616);
  static const Color surfaceHigh = Color(0xFF1C1C1E);
  static const Color hairline = Color(0xFF2C2C2E);

  static const Color midnight = Color(0xFF0A0A0A);
  static const Color deepNavy = Color(0xFF0F1115);
  static const Color skyNavy = Color(0xFF3A4A8C);
  static const Color horizon = Color(0xFF4A5A9A);
  static const Color accent = Color(0xFFF69306);
  static const Color accentSoft = Color(0xFFF6B35A);
  static const Color mist = Color(0xFFE8E8EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF8E8E93);
  static const Color mutedDark = Color(0xFF636366);

  static const Color signal = orange;
}

abstract final class BerpBrand {
  static const acronym = 'BERP';
  static const wordmark = 'BITACHON';
  static const line = 'ENTERPRISE';
  static const fullName = 'Bitachon Enterprise';
  static const logo = 'assets/images/berp_logo.png';
  static const appId = 'berp';
}
