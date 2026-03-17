import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'app_theme_mode';

final _themeInitProvider = FutureProvider<ThemeMode>((_) async {
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt(_themeKey);
  if (themeIndex != null &&
      themeIndex >= 0 &&
      themeIndex < ThemeMode.values.length) {
    return ThemeMode.values[themeIndex];
  }
  return ThemeMode.system;
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final asyncValue = ref.watch(_themeInitProvider);
  final initialMode = asyncValue.value ?? ThemeMode.system;
  return ThemeNotifier(initialMode);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(super.initialMode);

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }
}
