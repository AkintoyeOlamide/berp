import 'package:flutter/material.dart';

/// BERP brand colors sampled from the Bitachon mark.
abstract final class AppColors {
  static const Color brandBlue = Color(0xFF1F2D90);
  static const Color brandBlueDeep = Color(0xFF161F66);
  static const Color brandBlueGlow = Color(0xFF1E90FF);
  static const Color brandBlueSoft = Color(0xFF4D8AD8);

  /// Secondary brand color (dodger blue).
  static const Color secondary = Color(0xFF1E90FF);
  static const Color cyan = secondary;
  static const Color orange = Color(0xFFF69306);
  static const Color green = Color(0xFF75BD42);

  static const Color black = Color(0xFF070A12);
  static const Color blackElevated = Color(0xFF0D1220);
  static const Color surface = Color(0xFF12182A);
  static const Color surfaceHigh = Color(0xFF1A2238);
  static const Color hairline = Color(0xFF2A3348);

  static const Color midnight = Color(0xFF070A12);
  static const Color deepNavy = Color(0xFF0A1228);
  static const Color skyNavy = Color(0xFF1F2D90);
  static const Color horizon = Color(0xFF2F4DB8);
  static const Color accent = Color(0xFFF69306);
  static const Color accentSoft = secondary;
  static const Color mist = Color(0xFFE6ECF8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF9AA6BD);
  static const Color mutedDark = Color(0xFF6E7A91);

  static const Color signal = secondary;
}

abstract final class BerpBrand {
  static const acronym = 'BERP';
  static const wordmark = 'BITACHON';
  static const line = 'ENTERPRISE';
  static const fullName = 'Bitachon Enterprise';
  static const logo = 'assets/images/berp_logo.png';
  static const appId = 'berp';
}
