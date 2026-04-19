import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  const AppSettingsState({
    required this.isDarkTheme,
    required this.name,
    required this.dob,
    required this.profileImagePath,
  });

  factory AppSettingsState.initial() {
    return const AppSettingsState(
      isDarkTheme: true,
      name: null,
      dob: null,
      profileImagePath: null,
    );
  }

  final bool isDarkTheme;
  final String? name;
  final DateTime? dob;
  final String? profileImagePath;

  bool get hasProfile => name != null && dob != null;

  ThemeMode get themeMode => isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  AppSettingsState copyWith({
    bool? isDarkTheme,
    String? name,
    DateTime? dob,
    String? profileImagePath,
    bool clearProfileImagePath = false,
  }) {
    return AppSettingsState(
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      profileImagePath: clearProfileImagePath
          ? null
          : profileImagePath ?? this.profileImagePath,
    );
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettingsState>(
      AppSettingsController.new,
    );

class AppSettingsController extends AsyncNotifier<AppSettingsState> {
  static const _themePrefKey = 'theme_dark_mode';
  static const _nameKey = 'user_name';
  static const _dobKey = 'user_dob';
  static const _profileImageKey = 'user_profile_image';

  @override
  Future<AppSettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final dobMillis = prefs.getInt(_dobKey);
    return AppSettingsState(
      isDarkTheme: prefs.getBool(_themePrefKey) ?? true,
      name: prefs.getString(_nameKey),
      dob: dobMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dobMillis),
      profileImagePath: prefs.getString(_profileImageKey),
    );
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDark);
    final current = state.value ?? AppSettingsState.initial();
    state = AsyncValue.data(current.copyWith(isDarkTheme: isDark));
  }

  Future<void> saveProfile(String name, DateTime dob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setInt(_dobKey, dob.millisecondsSinceEpoch);
    final current = state.value ?? AppSettingsState.initial();
    state = AsyncValue.data(current.copyWith(name: name, dob: dob));
  }

  Future<void> saveProfileImage(String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanedPath = imagePath?.trim();
    final shouldClear = cleanedPath == null || cleanedPath.isEmpty;
    if (shouldClear) {
      await prefs.remove(_profileImageKey);
    } else {
      await prefs.setString(_profileImageKey, cleanedPath);
    }
    final current = state.value ?? AppSettingsState.initial();
    state = AsyncValue.data(
      current.copyWith(
        profileImagePath: shouldClear ? null : cleanedPath,
        clearProfileImagePath: shouldClear,
      ),
    );
  }
}
