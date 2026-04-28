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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, dailyEnabled);
    await prefs.setBool(_staleReminderEnabledKey, staleEnabled);
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
    await prefs.setInt(_staleReminderDaysKey, staleDays);
  }

  @override
  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDark);
  }
}
