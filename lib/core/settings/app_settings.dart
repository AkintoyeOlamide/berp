import 'package:flutter/material.dart';

import '../data/local_store.dart';

/// Global appearance preferences (theme + text size).
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  double _fontScale = 1.0;
  bool _ready = false;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get isReady => _ready;
  bool get isDark => _themeMode != ThemeMode.light;

  static const fontScaleOptions = <(String, double)>[
    ('Small', 0.9),
    ('Default', 1.0),
    ('Large', 1.15),
    ('Extra large', 1.3),
  ];

  Future<void> load() async {
    _themeMode = await LocalStore.instance.themeMode();
    _fontScale = await LocalStore.instance.fontScale();
    _ready = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await LocalStore.instance.setThemeMode(mode);
  }

  Future<void> setDark(bool dark) =>
      setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.4);
    if ((_fontScale - clamped).abs() < 0.001) return;
    _fontScale = clamped;
    notifyListeners();
    await LocalStore.instance.setFontScale(_fontScale);
  }
}
