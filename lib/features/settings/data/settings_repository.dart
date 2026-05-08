import '../models/app_settings.dart';

abstract class AppSettingsRepository {
  Future<int?> loadBirthdayAnnouncedYear();
  Future<AppSettings> load();
  Future<void> saveBirthdayAnnouncedYear(int year);
  Future<void> saveProfile(String name, DateTime dob);
  Future<void> saveProfileImage(String? imagePath);
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
  });
  Future<void> setDarkMode(bool isDark);
}
