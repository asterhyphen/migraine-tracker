import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.isDarkTheme,
    required this.name,
    required this.dob,
    required this.profileImagePath,
  });

  factory AppSettings.initial() {
    return const AppSettings(
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

  AppSettings copyWith({
    bool? isDarkTheme,
    String? name,
    DateTime? dob,
    String? profileImagePath,
    bool clearProfileImagePath = false,
  }) {
    return AppSettings(
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      profileImagePath: clearProfileImagePath
          ? null
          : profileImagePath ?? this.profileImagePath,
    );
  }
}
