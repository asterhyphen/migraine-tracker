import '../models/app_settings.dart';

abstract class AppSettingsRepository {
  Future<int?> loadBirthdayAnnouncedYear();
  Future<AppSettings> load();
  Future<void> saveBirthdayAnnouncedYear(int year);
  Future<void> saveProfile(String name, DateTime dob);
  Future<void> saveProfileImage(String? imagePath);
  Future<void> setDarkMode(bool isDark);
}
