import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.dark;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefThemeMode);
    if (saved != null) {
      if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    await prefs.setString(AppConstants.prefThemeMode, value);
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class CurrencyNotifier extends Notifier<AppCurrency> {
  @override
  AppCurrency build() {
    _loadFromPrefs();
    return AppCurrency.usd;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefCurrency);
    if (saved != null) {
      state = AppCurrency.fromCode(saved);
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCurrency, currency.code);
  }

  Future<void> toggleCurrency() async {
    const values = AppCurrency.values;
    final currentIndex = values.indexOf(state);
    final next = values[(currentIndex + 1) % values.length];
    await setCurrency(next);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, AppCurrency>(
  CurrencyNotifier.new,
);
