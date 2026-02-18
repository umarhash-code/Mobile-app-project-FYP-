import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'en';
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _temperatureUnit = 'celsius';
  String _timeFormat = '12hour';

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationEnabled => _locationEnabled;
  String get temperatureUnit => _temperatureUnit;
  String get timeFormat => _timeFormat;

  // Theme data getters
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B73FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B73FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      );

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Initialize theme provider
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _language = prefs.getString('language') ?? 'en';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _locationEnabled = prefs.getBool('locationEnabled') ?? true;
    _temperatureUnit = prefs.getString('temperatureUnit') ?? 'celsius';
    _timeFormat = prefs.getString('timeFormat') ?? '12hour';
    notifyListeners();
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    notifyListeners();
  }

  // Toggle notifications
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    notifyListeners();
  }

  // Toggle location
  Future<void> toggleLocation() async {
    _locationEnabled = !_locationEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationEnabled', _locationEnabled);
    notifyListeners();
  }

  // Set temperature unit
  Future<void> setTemperatureUnit(String unit) async {
    _temperatureUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temperatureUnit', _temperatureUnit);
    notifyListeners();
  }

  // Set time format
  Future<void> setTimeFormat(String format) async {
    _timeFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timeFormat', _timeFormat);
    notifyListeners();
  }

  // Reset all settings
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isDarkMode = false;
    _language = 'en';
    _notificationsEnabled = true;
    _locationEnabled = true;
    _temperatureUnit = 'celsius';
    _timeFormat = '12hour';
    notifyListeners();
  }
}
