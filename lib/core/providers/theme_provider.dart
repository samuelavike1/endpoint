import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────── Theme Provider ────────────────
// Controls dark/light mode across the entire app.

enum AppThemeMode { dark, light }

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    state = isDark ? AppThemeMode.dark : AppThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', state == AppThemeMode.dark);
  }

  bool get isDark => state == AppThemeMode.dark;
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
