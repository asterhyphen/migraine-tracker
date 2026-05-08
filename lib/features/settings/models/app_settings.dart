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
    required this.forceDailyReminder,
    required this.dailyReminderMessage,
    required this.staleReminderMessage,
    required this.medicationReminders,
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
      forceDailyReminder: false,
      dailyReminderMessage:
          'A quick note today can make your migraine patterns clearer.',
      staleReminderMessage:
          'It has been a few days since your last log. Add a quick update when you can.',
      medicationReminders: [],
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
  final bool forceDailyReminder;
  final String dailyReminderMessage;
  final String staleReminderMessage;
  final List<MedicationReminder> medicationReminders;

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
    bool? forceDailyReminder,
    String? dailyReminderMessage,
    String? staleReminderMessage,
    List<MedicationReminder>? medicationReminders,
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
      forceDailyReminder: forceDailyReminder ?? this.forceDailyReminder,
      dailyReminderMessage: dailyReminderMessage ?? this.dailyReminderMessage,
      staleReminderMessage: staleReminderMessage ?? this.staleReminderMessage,
      medicationReminders: medicationReminders ?? this.medicationReminders,
    );
  }
}

class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final String id;
  final String name;
  final int hour;
  final int minute;
  final bool enabled;

  MedicationReminder copyWith({
    String? id,
    String? name,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
    };
  }

  factory MedicationReminder.fromJson(Map<String, Object?> json) {
    return MedicationReminder(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Medication',
      hour: _coerceInt(json['hour'], min: 0, max: 23, fallback: 9),
      minute: _coerceInt(json['minute'], min: 0, max: 59, fallback: 0),
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }

  static int _coerceInt(
    Object? value, {
    required int min,
    required int max,
    required int fallback,
  }) {
    if (value is! num) return fallback;
    return value.toInt().clamp(min, max);
  }
}
