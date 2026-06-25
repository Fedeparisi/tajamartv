import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _themeKey = 'selected_theme_mode';

  @override
  AppThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      return AppThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => AppThemeMode.dark,
      );
    }
    return AppThemeMode.dark;
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_themeKey, mode.toString());
  }
  
  ThemeData get currentThemeData {
    switch (state) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.midnight:
        return AppTheme.midnightTheme;
      case AppThemeMode.dark:
      default:
        return AppTheme.darkTheme;
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});
