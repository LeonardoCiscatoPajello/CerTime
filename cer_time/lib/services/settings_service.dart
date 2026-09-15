import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimeFormatMode { decimal , hhmm }

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();


  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyTimeFormat = 'settings_time_format';
  static const _keyOnboardingDone = 'settings_onboarding_done';

  ThemeMode _themeMode = ThemeMode.system;
  TimeFormatMode _timeformat = TimeFormatMode.decimal;

  bool _onboardingDone = false;
  bool _initialized = false;

  ThemeMode  get themeMode => _themeMode;
  TimeFormatMode get timeFormat => _timeformat;
  bool get onboardingDone => _onboardingDone;

  Future<void> init() async {
    if(_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_keyDarkMode);
    _themeMode = isDark == null ? ThemeMode.system : (isDark ? ThemeMode.dark : ThemeMode.light);
    final formatIndex = prefs.getInt(_keyTimeFormat) ?? 0;
    _timeformat = TimeFormatMode.values[formatIndex];
    _onboardingDone = prefs.getBool(_keyOnboardingDone) ?? false;
    _initialized = true;
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
  }

  Future<void> setTimeFormat(TimeFormatMode mode) async {
    _timeformat = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeFormat, mode.index);
  }

  Future<void> setOnboardingDone() async {
    _onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }
}




