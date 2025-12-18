import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/theme/app_theme_data.dart';

/// Provider to manage app theme state
class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  // Cache theme configs for performance
  final AppThemeConfig _lightConfig = AppThemeConfig.light();
  final AppThemeConfig _darkConfig = AppThemeConfig.dark();
  
  ThemeMode get themeMode => _themeMode;
  
  /// Get the light theme configuration
  AppThemeConfig get lightConfig => _lightConfig;
  
  /// Get the dark theme configuration
  AppThemeConfig get darkConfig => _darkConfig;
  
  /// Get the light ThemeData
  ThemeData get lightTheme => _lightConfig.toThemeData();
  
  /// Get the dark ThemeData
  ThemeData get darkTheme => _darkConfig.toThemeData();
  
  /// Get the current theme config based on context brightness
  AppThemeConfig getConfig(BuildContext context) {
    return isDarkMode(context) ? _darkConfig : _lightConfig;
  }
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  /// Load saved theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themePreferenceKey);
    
    if (savedThemeMode != null) {
      _themeMode = _getThemeModeFromString(savedThemeMode);
      notifyListeners();
    }
  }
  
  /// Save theme preference
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, mode.toString());
  }
  
  /// Convert string to ThemeMode
  ThemeMode _getThemeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    await _saveThemePreference(mode);
  }
  
  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    await setThemeMode(newMode);
  }
  
  /// Check if dark mode is active
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
