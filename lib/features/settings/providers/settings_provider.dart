import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_prefs_settings_repository.dart';
import '../data/settings_repository.dart';
import '../models/app_settings.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => const SharedPrefsSettingsRepository(),
);

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends AsyncNotifier<AppSettings> {
  AppSettingsRepository get _repository =>
      ref.read(appSettingsRepositoryProvider);

  @override
  Future<AppSettings> build() {
    return _repository.load();
  }

  Future<void> setDarkMode(bool isDark) async {
    await _repository.setDarkMode(isDark);
    final current = state.value ?? AppSettings.initial();
    state = AsyncValue.data(current.copyWith(isDarkTheme: isDark));
  }

  Future<void> saveProfile(String name, DateTime dob) async {
    await _repository.saveProfile(name, dob);
    final current = state.value ?? AppSettings.initial();
    state = AsyncValue.data(current.copyWith(name: name, dob: dob));
  }

  Future<void> saveProfileImage(String? imagePath) async {
    await _repository.saveProfileImage(imagePath);
    final cleanedPath = imagePath?.trim();
    final shouldClear = cleanedPath == null || cleanedPath.isEmpty;
    final current = state.value ?? AppSettings.initial();
    state = AsyncValue.data(
      current.copyWith(
        profileImagePath: shouldClear ? null : cleanedPath,
        clearProfileImagePath: shouldClear,
      ),
    );
  }

  Future<void> saveReminderSettings({
    required bool dailyEnabled,
    required bool staleEnabled,
    required int hour,
    required int minute,
    required int staleDays,
  }) async {
    await _repository.saveReminderSettings(
      dailyEnabled: dailyEnabled,
      staleEnabled: staleEnabled,
      hour: hour,
      minute: minute,
      staleDays: staleDays,
    );
    final current = state.value ?? AppSettings.initial();
    state = AsyncValue.data(
      current.copyWith(
        dailyReminderEnabled: dailyEnabled,
        staleReminderEnabled: staleEnabled,
        reminderHour: hour,
        reminderMinute: minute,
        staleReminderDays: staleDays,
      ),
    );
  }
}
