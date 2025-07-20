import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_utils.dart';

class ThemeManager {
  static const String _themePreferenceKey = 'selected_theme';
  static const String _amoledModeKey = 'amoled_mode_enabled';

  static const Map<String, Color> themeColors = {
    'Adaptive Theme':
        Colors.blueGrey, // Default dynamic colors from system wallpaper
    'Amber': Colors.amber,
    'Ocean Blue': Colors.blue,
    'Forest Green': Colors.green,
    'Sunset Orange': Colors.orange,
    'Purple Rain': Colors.purple,
    'Cherry Red': Colors.red,
    'Sky Cyan': Colors.cyan,
    'Pink Blossom': Colors.pink,
    'Lime Fresh': Colors.lime,
    'Deep Purple': Colors.deepPurple,
    'Teal Wave': Colors.teal,
    'Indigo Night': Colors.indigo,
  };

  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themePreferenceKey) ?? 'Adaptive Theme';
  }

  static Future<void> setSelectedTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeName);
  }

  static Future<bool> getAmoledMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_amoledModeKey) ?? false;
  }

  static Future<void> setAmoledMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledModeKey, enabled);
  }

  static Color getThemeColor(String themeName) {
    return themeColors[themeName] ?? Colors.blueGrey;
  }

  static List<String> getAvailableThemes() {
    return themeColors.keys.toList();
  }

  /// Creates color schemes based on selected theme and dynamic colors
  static (ColorScheme light, ColorScheme dark) createColorSchemes({
    required ColorScheme? lightDynamic,
    required ColorScheme? darkDynamic,
    required String selectedTheme,
    required bool amoledModeEnabled,
  }) {
    ColorScheme lightScheme;
    ColorScheme darkScheme;

    // Use dynamic colors if available and "Adaptive Theme" is selected
    if (selectedTheme == 'Adaptive Theme' &&
        lightDynamic != null &&
        darkDynamic != null) {
      lightScheme = lightDynamic;
      darkScheme = darkDynamic;
    } else {
      final seedColor = getThemeColor(selectedTheme);
      lightScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      );
      darkScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      );
    }

    // Apply AMOLED mode if enabled
    if (amoledModeEnabled) {
      darkScheme = ThemeUtils.createAmoledColorScheme(darkScheme);
    }

    return (lightScheme, darkScheme);
  }
}
