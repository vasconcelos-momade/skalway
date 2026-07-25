import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Tema global da app (Material light/dark).
class AppThemeMode extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isDark = prefs.getBool(_key);
    if (isDark == null) return ThemeMode.light;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    final prefs = ref.read(sharedPreferencesProvider);
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    prefs.setBool(_key, newMode == ThemeMode.dark);
    state = newMode;
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeMode, ThemeMode>(AppThemeMode.new);
