import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/secure_kv_service.dart';

const String _keyThemeMode = 'themeMode';

ThemeMode themeModeFromString(String? value) {
  switch (value) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.light;
  }
}

String themeModeToString(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
  };
}

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._storage) : super(ThemeMode.light) {
    _loadStored();
  }

  final SecureKvService _storage;

  void _loadStored() {
    _storage.getString(_keyThemeMode).then((value) {
      if (value != null) {
        state = themeModeFromString(value);
      }
    });
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _storage.setString(_keyThemeMode, themeModeToString(mode));
  }
}
