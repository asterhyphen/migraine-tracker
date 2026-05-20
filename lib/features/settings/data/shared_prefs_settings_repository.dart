import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'settings_repository.dart';

class SharedPrefsSettingsRepository implements AppSettingsRepository {
  const SharedPrefsSettingsRepository();

  static const _themePrefKey = 'theme_dark_mode';
  static const _nameKey = 'user_name';
  static const _dobKey = 'user_dob';
  static const _profileImageKey = 'user_profile_image';
  static const _birthdayAnnouncedYearKey = 'birthday_announced_year';
  static const _dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const _staleReminderEnabledKey = 'stale_reminder_enabled';
  static const _reminderHourKey = 'reminder_hour';
  static const _reminderMinuteKey = 'reminder_minute';
  static const _staleReminderDaysKey = 'stale_reminder_days';
  static const _forceDailyReminderKey = 'force_daily_reminder';
  static const _dailyReminderMessageKey = 'daily_reminder_message';
  static const _staleReminderMessageKey = 'stale_reminder_message';
  static const _medicationRemindersKey = 'medication_reminders';

  @override
  Future<int?> loadBirthdayAnnouncedYear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_birthdayAnnouncedYearKey);
  }

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dobMillis = prefs.getInt(_dobKey);
    return AppSettings(
      isDarkTheme: prefs.getBool(_themePrefKey) ?? true,
      name: prefs.getString(_nameKey),
      dob: dobMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dobMillis),
      profileImagePath: prefs.getString(_profileImageKey),
      dailyReminderEnabled: prefs.getBool(_dailyReminderEnabledKey) ?? false,
      staleReminderEnabled: prefs.getBool(_staleReminderEnabledKey) ?? false,
      reminderHour: prefs.getInt(_reminderHourKey) ?? 20,
      reminderMinute: prefs.getInt(_reminderMinuteKey) ?? 30,
      staleReminderDays: prefs.getInt(_staleReminderDaysKey) ?? 3,
      forceDailyReminder: prefs.getBool(_forceDailyReminderKey) ?? false,
      dailyReminderMessage:
          prefs.getString(_dailyReminderMessageKey) ??
          'A quick note today can make your migraine patterns clearer.',
      staleReminderMessage:
          prefs.getString(_staleReminderMessageKey) ??
          'It has been a few days since your last log. Add a quick update when you can.',
      medicationReminders: _loadMedicationReminders(
        prefs.getString(_medicationRemindersKey),
      ),
    );
  }

  @override
  Future<void> saveProfile(String name, DateTime dob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setInt(_dobKey, dob.millisecondsSinceEpoch);
  }

  @override
  Future<void> saveBirthdayAnnouncedYear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_birthdayAnnouncedYearKey, year);
  }

  @override
  Future<void> saveProfileImage(String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanedPath = imagePath?.trim();
    if (cleanedPath == null || cleanedPath.isEmpty) {
      await prefs.remove(_profileImageKey);
    } else {
      await prefs.setString(_profileImageKey, cleanedPath);
    }
  }

  @override
  Future<void> saveReminderSettings({
    required bool dailyEnabled,
    required bool staleEnabled,
    required int hour,
    required int minute,
    required int staleDays,
    required bool forceDailyReminder,
    required String dailyMessage,
    required String staleMessage,
    required List<MedicationReminder> medicationReminders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, dailyEnabled);
    await prefs.setBool(_staleReminderEnabledKey, staleEnabled);
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
    await prefs.setInt(_staleReminderDaysKey, staleDays);
    await prefs.setBool(_forceDailyReminderKey, forceDailyReminder);
    await prefs.setString(_dailyReminderMessageKey, dailyMessage);
    await prefs.setString(_staleReminderMessageKey, staleMessage);
    await prefs.setString(
      _medicationRemindersKey,
      jsonEncode(
        medicationReminders.map((reminder) => reminder.toJson()).toList(),
      ),
    );
  }

  @override
  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDark);
  }

  static List<MedicationReminder> _loadMedicationReminders(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => MedicationReminder.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
