import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

/// Провайдер текущей темы приложения (Riverpod).
/// Меняется из профиля; синхронизируется с [AppTheme].
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => AppTheme.themeMode;

  void setTheme(ThemeMode mode) {
    AppTheme.setThemeMode(mode);
    state = mode;
  }
}
