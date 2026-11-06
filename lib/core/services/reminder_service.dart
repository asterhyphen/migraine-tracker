import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:migraine_tracker/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:migraine_tracker/features/settings/models/app_settings.dart';
import 'package:migraine_tracker/features/tracker/data/migraine_db.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = FlutterLocalNotificationsPlugin();
  if (response.id != null) {
    await notifications.cancel(id: response.id!);
  }
  await notifications.cancel(id: ReminderService.dailySurveyId);
  await notifications.cancel(id: ReminderService.followUpReminderId);

  if (response.actionId == ReminderService.surveyActionNo) {
    final today = DateTime.now();
    final existing = await MigraineDb.instance.getAnyEntryForDate(today);
    if (existing != null) {
      final updated = existing.copyWith(
        hadMigraine: false,
        intensity: 0,
        painkillers: false,
        notes: existing.notes.isEmpty
            ? 'Daily check-in: Pain-free'
            : existing.notes,
      );
      await MigraineDb.instance.updateEntry(updated);
    } else {
      final entry = MigraineEntry(
        date: today,
        hadMigraine: false,
        intensity: 0,
        painkillers: false,
        notes: 'Daily check-in: Pain-free',
        causes: const [],
      );
      await MigraineDb.instance.insertEntry(entry);
    }

    final prefsRepo = const SharedPrefsSettingsRepository();
    final settings = await prefsRepo.load();
    final allEntries = await MigraineDb.instance.getAllEntries();
    await ReminderService.instance.reschedule(
      settings: settings,
      entries: allEntries,
      hasLoggedToday: true,
    );
  } else if (response.actionId == ReminderService.followUpActionResolved ||
      response.actionId == ReminderService.followUpActionPersisted) {
    final outcome = response.actionId == ReminderService.followUpActionResolved
        ? MigraineOutcome.resolved
        : MigraineOutcome.persisted;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final existing = await MigraineDb.instance.getEntryForDate(yesterday);
    if (existing != null && existing.hadMigraine) {
      await MigraineDb.instance.updateEntry(existing.copyWith(outcome: outcome));
    } else {
      final migraines = await MigraineDb.instance.getMigraineEntriesOnly();
      if (migraines.isNotEmpty && migraines.first.outcome == MigraineOutcome.unknown) {
        await MigraineDb.instance.updateEntry(
          migraines.first.copyWith(outcome: outcome),
        );
      }
    }
    final prefsRepo = const SharedPrefsSettingsRepository();
    final settings = await prefsRepo.load();
    final allEntries = await MigraineDb.instance.getAllEntries();
    await ReminderService.instance.reschedule(
      settings: settings,
      entries: allEntries,
    );
  }
}

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const logPayload = 'open-log';
  static const surveyPayload = 'daily-survey';
  static const surveyActionYes = 'survey_yes';
  static const surveyActionNo = 'survey_no';
  static const followUpPayload = 'followup-persistence';
  static const followUpActionResolved = 'follow_up_resolved';
  static const followUpActionPersisted = 'follow_up_persisted';
  static const _dailyReminderId = 701;
  static const _staleReminderId = 702;
  static const dailySurveyId = 705;
  static const _dailySurveyId = dailySurveyId;
  static const followUpReminderId = 708;
  static const _followUpReminderId = followUpReminderId;
  static const _medicationReminderBaseId = 720;
  static const _maxMedicationReminders = 50;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _handledLaunchNotification = false;

  Future<void> initialize({
    void Function()? onLogRequested,
    void Function(bool hadMigraine)? onSurveyResponse,
    void Function(MigraineOutcome outcome)? onFollowUpResponse,
  }) async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'daily_survey_category',
          actions: [
            DarwinNotificationAction.plain(
              surveyActionYes,
              'Yes, had migraine',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              surveyActionNo,
              'No, pain-free',
            ),
          ],
        ),
        DarwinNotificationCategory(
          'follow_up_category',
          actions: [
            DarwinNotificationAction.plain(
              followUpActionResolved,
              'Got Better',
            ),
            DarwinNotificationAction.plain(
              followUpActionPersisted,
              'Persisted',
            ),
          ],
        ),
      ],
    );
    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.id != null) {
          await _notifications.cancel(id: response.id!);
        }
        await _notifications.cancel(id: _dailySurveyId);
        await _notifications.cancel(id: _followUpReminderId);

        if (response.actionId == surveyActionYes) {
          onSurveyResponse?.call(true);
        } else if (response.actionId == surveyActionNo) {
          onSurveyResponse?.call(false);
        } else if (response.actionId == followUpActionResolved ||
            response.actionId == followUpActionPersisted) {
          final outcome = response.actionId == followUpActionResolved
              ? MigraineOutcome.resolved
              : MigraineOutcome.persisted;
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final existing = await MigraineDb.instance.getEntryForDate(yesterday);
          if (existing != null && existing.hadMigraine) {
            await MigraineDb.instance.updateEntry(
              existing.copyWith(outcome: outcome),
            );
          } else {
            final migraines = await MigraineDb.instance.getMigraineEntriesOnly();
            if (migraines.isNotEmpty && migraines.first.outcome == MigraineOutcome.unknown) {
              await MigraineDb.instance.updateEntry(
                migraines.first.copyWith(outcome: outcome),
              );
            }
          }
          onFollowUpResponse?.call(outcome);
        } else if (response.payload == surveyPayload ||
            response.payload == logPayload ||
            response.payload == followUpPayload) {
          onLogRequested?.call();
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _initialized = true;

    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (!_handledLaunchNotification &&
        launchDetails?.didNotificationLaunchApp == true &&
        response != null) {
      _handledLaunchNotification = true;
      if (response.id != null) {
        await _notifications.cancel(id: response.id!);
      }
      await _notifications.cancel(id: _dailySurveyId);
      await _notifications.cancel(id: _followUpReminderId);

      if (response.actionId == surveyActionYes) {
        onSurveyResponse?.call(true);
      } else if (response.actionId == surveyActionNo) {
        onSurveyResponse?.call(false);
      } else if (response.actionId == followUpActionResolved ||
          response.actionId == followUpActionPersisted) {
        final outcome = response.actionId == followUpActionResolved
            ? MigraineOutcome.resolved
            : MigraineOutcome.persisted;
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final existing = await MigraineDb.instance.getEntryForDate(yesterday);
        if (existing != null && existing.hadMigraine) {
          await MigraineDb.instance.updateEntry(
            existing.copyWith(outcome: outcome),
          );
        } else {
          final migraines = await MigraineDb.instance.getMigraineEntriesOnly();
          if (migraines.isNotEmpty && migraines.first.outcome == MigraineOutcome.unknown) {
            await MigraineDb.instance.updateEntry(
              migraines.first.copyWith(outcome: outcome),
            );
          }
        }
        onFollowUpResponse?.call(outcome);
      } else if (response.payload == surveyPayload ||
          response.payload == logPayload ||
          response.payload == followUpPayload) {
        onLogRequested?.call();
      }
    }
  }

  Future<bool> requestPermission() async {
    await initialize();

    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return result ?? true;
    }
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isMacOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  Future<void> reschedule({
    required AppSettings settings,
    required List<MigraineEntry> entries,
    bool? hasLoggedToday,
  }) async {
    await initialize();
    await _notifications.cancel(id: _dailyReminderId);
    await _notifications.cancel(id: _staleReminderId);
    await _notifications.cancel(id: _dailySurveyId);
    await _notifications.cancel(id: _followUpReminderId);
    await _cancelMedicationReminders();

    final isLoggedToday = hasLoggedToday ?? _hasLoggedToday(entries);

    if (settings.dailyReminderEnabled) {
      if (settings.forceDailyReminder) {
        await _scheduleDaily(settings, forceTomorrow: false);
      } else if (!isLoggedToday) {
        await _scheduleDaily(settings, forceTomorrow: false);
      } else {
        await _scheduleDaily(settings, forceTomorrow: true);
      }
    }

    if (settings.dailySurveyEnabled) {
      if (!isLoggedToday) {
        await _scheduleDailySurvey(settings, forceTomorrow: false);
      } else {
        // If already logged/checked in today, do not ask again today.
        // Schedule the recurring survey starting tomorrow.
        await _scheduleDailySurvey(settings, forceTomorrow: true);
      }
    }

    if (settings.staleReminderEnabled) {
      await _scheduleStaleReminder(settings, entries);
    }

    await _scheduleFollowUpReminder(settings, entries);
    await _scheduleMedicationReminders(settings.medicationReminders);
  }

  bool _hasLoggedToday(List<MigraineEntry> entries) {
    final now = DateTime.now();
    return entries.any((entry) {
      return entry.date.year == now.year &&
          entry.date.month == now.month &&
          entry.date.day == now.day;
    });
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    await _notifications.cancel(id: _dailyReminderId);
    await _notifications.cancel(id: _staleReminderId);
    await _notifications.cancel(id: _dailySurveyId);
    await _notifications.cancel(id: _followUpReminderId);
    await _cancelMedicationReminders();
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
  }

  Future<void> _scheduleDaily(
    AppSettings settings, {
    bool forceTomorrow = false,
  }) async {
    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: 'Time to log your symptoms',
      body: settings.dailyReminderMessage,
      scheduledDate: _nextTime(
        settings.reminderHour,
        settings.reminderMinute,
        forceTomorrow: forceTomorrow,
      ),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: logPayload,
    );
  }

  Future<void> _scheduleDailySurvey(
    AppSettings settings, {
    bool forceTomorrow = false,
  }) async {
    await _notifications.zonedSchedule(
      id: _dailySurveyId,
      title: 'Daily Check-in',
      body: 'Did you have a migraine today?',
      scheduledDate: _nextTime(
        settings.dailySurveyHour,
        settings.dailySurveyMinute,
        forceTomorrow: forceTomorrow,
      ),
      notificationDetails: _surveyNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: surveyPayload,
    );
  }

  Future<void> _scheduleStaleReminder(
    AppSettings settings,
    List<MigraineEntry> entries,
  ) async {
    final latest = entries.isEmpty ? null : entries.first.date;
    final base = latest ?? DateTime.now();
    final next = DateTime(
      base.year,
      base.month,
      base.day + settings.staleReminderDays,
      settings.reminderHour,
      settings.reminderMinute,
    );
    var scheduled = tz.TZDateTime.from(next, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(now)) {
      scheduled = _nextTime(settings.reminderHour, settings.reminderMinute);
    }

    await _notifications.zonedSchedule(
      id: _staleReminderId,
      title: 'Want to check in?',
      body: settings.staleReminderMessage,
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: logPayload,
    );
  }

  Future<void> _scheduleMedicationReminders(
    List<MedicationReminder> reminders,
  ) async {
    final enabled = reminders
        .where((reminder) => reminder.enabled)
        .take(_maxMedicationReminders);
    var index = 0;
    for (final reminder in enabled) {
      await _notifications.zonedSchedule(
        id: _medicationReminderBaseId + index,
        title: 'Medication reminder',
        body: 'Time to take ${reminder.name}.',
        scheduledDate: _nextTime(reminder.hour, reminder.minute),
        notificationDetails: _medicationNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      index += 1;
    }
  }

  Future<void> _cancelMedicationReminders() async {
    for (var i = 0; i < _maxMedicationReminders; i += 1) {
      await _notifications.cancel(id: _medicationReminderBaseId + i);
    }
  }

  tz.TZDateTime _nextTime(
    int hour,
    int minute, {
    bool forceTomorrow = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (forceTomorrow || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      'migraine_log_reminders',
      'Log reminders',
      channelDescription: 'Reminders to log migraine symptoms.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
    );
    const darwin = DarwinNotificationDetails();
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }

  NotificationDetails _surveyNotificationDetails() {
    const android = AndroidNotificationDetails(
      'migraine_survey_reminders',
      'Daily check-in survey',
      channelDescription: 'Quick daily survey to record migraine status.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
      actions: [
        AndroidNotificationAction(
          surveyActionYes,
          'Yes',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          surveyActionNo,
          'No',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const darwin = DarwinNotificationDetails(
      categoryIdentifier: 'daily_survey_category',
    );
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }

  NotificationDetails _medicationNotificationDetails() {
    const android = AndroidNotificationDetails(
      'medication_reminders',
      'Medication reminders',
      channelDescription: 'Reminders to take migraine-related medication.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
    );
    const darwin = DarwinNotificationDetails();
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }

  Future<void> _scheduleFollowUpReminder(
    AppSettings settings,
    List<MigraineEntry> entries,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Look for the most recent migraine entry that is pending follow-up (outcome == unknown)
    MigraineEntry? targetEntry;
    DateTime? fireDate;

    for (final entry in entries) {
      if (!entry.hadMigraine) continue;
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      if (entryDate == today && entry.outcome == MigraineOutcome.unknown) {
        // Today has a migraine logged! Schedule follow-up for tomorrow morning.
        targetEntry = entry;
        fireDate = today.add(const Duration(days: 1));
        break;
      } else if (entryDate == yesterday &&
          entry.outcome == MigraineOutcome.unknown) {
        // Yesterday had a migraine and outcome is still unknown! Schedule for today.
        targetEntry = entry;
        fireDate = today;
        break;
      }
    }

    if (targetEntry == null || fireDate == null) {
      return;
    }

    final hour = settings.dailySurveyEnabled ? settings.dailySurveyHour : 9;
    final minute = settings.dailySurveyEnabled ? settings.dailySurveyMinute : 0;
    var scheduled = tz.TZDateTime(
      tz.local,
      fireDate.year,
      fireDate.month,
      fireDate.day,
      hour,
      minute,
    );

    final nowTz = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(nowTz)) {
      if (fireDate == today) {
        // If scheduled time today already passed, trigger within 10 seconds so the user gets asked today
        scheduled = nowTz.add(const Duration(seconds: 10));
      } else {
        return;
      }
    }

    await _notifications.zonedSchedule(
      id: _followUpReminderId,
      title: 'Migraine Follow-up',
      body:
          "Did yesterday's migraine persist until the end of the day or did you get well eventually?",
      scheduledDate: scheduled,
      notificationDetails: _followUpNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: followUpPayload,
    );
  }

  NotificationDetails _followUpNotificationDetails() {
    const android = AndroidNotificationDetails(
      'migraine_followup_reminders',
      'Migraine follow-up',
      channelDescription:
          'Next-day follow-up to record whether your migraine persisted.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
      actions: [
        AndroidNotificationAction(
          followUpActionResolved,
          'Got Better',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          followUpActionPersisted,
          'Persisted',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const darwin = DarwinNotificationDetails(
      categoryIdentifier: 'follow_up_category',
    );
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }
}
