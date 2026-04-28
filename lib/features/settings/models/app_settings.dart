import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.isDarkTheme,
    required this.name,
    required this.dob,
    required this.profileImagePath,
    required this.dailyReminderEnabled,
    required this.staleReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.staleReminderDays,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      isDarkTheme: true,
      name: null,
      dob: null,
      profileImagePath: null,
      dailyReminderEnabled: false,
      staleReminderEnabled: false,
      reminderHour: 20,
      reminderMinute: 30,
      staleReminderDays: 3,
    );
  }

  final bool isDarkTheme;
  final String? name;
  final DateTime? dob;
  final String? profileImagePath;
  final bool dailyReminderEnabled;
  final bool staleReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int staleReminderDays;

  bool get hasProfile => name != null && dob != null;

  ThemeMode get themeMode => isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  AppSettings copyWith({
    bool? isDarkTheme,
    String? name,
    DateTime? dob,
    String? profileImagePath,
    bool? dailyReminderEnabled,
    bool? staleReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? staleReminderDays,
    bool clearProfileImagePath = false,
  }) {
    return AppSettings(
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      profileImagePath: clearProfileImagePath
          ? null
          : profileImagePath ?? this.profileImagePath,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      staleReminderEnabled: staleReminderEnabled ?? this.staleReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      staleReminderDays: staleReminderDays ?? this.staleReminderDays,
    );
  }
}
