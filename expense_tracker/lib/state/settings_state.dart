import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/currency.dart';
import '../utils/format.dart';

/// App-wide preferences persisted on device (not on the server):
/// theme mode and display currency.
class SettingsState extends ChangeNotifier {
  static const _themeKey = 'pref_theme_mode';
  static const _currencyKey = 'pref_currency';

  ThemeMode themeMode = ThemeMode.system;
  String currencyCode = 'USD';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey);
    if (theme != null) {
      themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      );
    }
    final currency = prefs.getString(_currencyKey);
    if (currency != null) currencyCode = currency;
    Money.configure(findCurrency(currencyCode));
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setCurrency(String code) async {
    currencyCode = code;
    Money.configure(findCurrency(code));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }
}
