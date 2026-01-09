import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences prefs;

  ThemeCubit(this.prefs) : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = prefs.getBool('darkMode') ?? false;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    prefs.setBool('darkMode', newMode == ThemeMode.dark);
    emit(newMode);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}