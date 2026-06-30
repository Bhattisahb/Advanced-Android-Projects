import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
  bool _darkMode = false;

  bool get darkMode => _darkMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  toggleTheme() {
    _darkMode = !_darkMode;
    _saveToPrefs();
    notifyListeners();
  }

  _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    _darkMode = _prefs?.getBool(key) ?? false;
    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    _prefs?.setBool(key, _darkMode);
  }

  ThemeData get themeData {
    return _darkMode ? _darkTheme : _lightTheme;
  }
  static final Color _seedColor = const Color(0xFF1565C0); // professional indigo

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: ColorScheme.fromSeed(seedColor: _seedColor).surface,
      foregroundColor: ColorScheme.fromSeed(seedColor: _seedColor).onSurface,
      centerTitle: true,
      surfaceTintColor: ColorScheme.fromSeed(seedColor: _seedColor).primary,
    ),
    scaffoldBackgroundColor: Color(0xFFF5F7FA),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorScheme.fromSeed(seedColor: _seedColor).primary,
      foregroundColor: ColorScheme.fromSeed(seedColor: _seedColor).onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.fromSeed(seedColor: _seedColor).primary,
        foregroundColor: ColorScheme.fromSeed(seedColor: _seedColor).onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    ),
    cardColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: Typography.material2021().black.apply(fontFamily: 'Roboto'),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFF0B1220),
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    scaffoldBackgroundColor: const Color(0xFF071026),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark).primary,
      foregroundColor: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark).onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark).primary,
        foregroundColor: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark).onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    ),
    cardColor: const Color(0xFF071026),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: Typography.material2021().white.apply(fontFamily: 'Roboto'),
  );
}