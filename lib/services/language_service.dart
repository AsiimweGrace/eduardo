import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static Locale? _locale;

  static Locale get locale => _locale ?? const Locale('en');

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
  }

  /// Call this to switch language instantly across the whole app
  static Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);

    // This triggers an immediate rebuild of MaterialApp via localeNotifier
    // Import main.dart's localeNotifier wherever you call setLocale
    // We use a callback pattern to avoid circular imports
    _onLocaleChanged?.call(locale);
  }

  // Register this callback from main.dart
  static void Function(Locale)? _onLocaleChanged;
  static void registerLocaleCallback(void Function(Locale) callback) {
    _onLocaleChanged = callback;
  }

  static bool get isEnglish => _locale?.languageCode == 'en';
  static bool get isRunyankole => _locale?.languageCode == 'rw';
}