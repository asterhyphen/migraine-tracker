import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:migraine_tracker/features/settings/models/app_settings.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const logPayload = 'open-log';
  static const surveyPayload = 'daily-survey';
  static const surveyActionYes = 'survey_yes';
  static const surveyActionNo = 'survey_no';
  static const _dailyReminderId = 701;
  static const _staleReminderId = 702;
  static const _dailySurveyId = 705;
  static const _medicationReminderBaseId = 720;
  static const _maxMedicationReminders = 50;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _handledLaunchNotification = false;

  Future<void> initialize({
    void Function()? onLogRequested,
    void Function(bool hadMigraine)? onSurveyResponse,
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
      ],
    );
    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == surveyActionYes) {
          onSurveyResponse?.call(true);
        } else if (response.actionId == surveyActionNo) {
          onSurveyResponse?.call(false);
        } else if (response.payload == surveyPayload) {
          onLogRequested?.call();
        } else if (response.payload == logPayload) {
          onLogRequested?.call();
        }
      },
    );
    _initialized = true;

    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (!_handledLaunchNotification &&
        launchDetails?.didNotificationLaunchApp == true &&
        response != null) {
      _handledLaunchNotification = true;
      if (response.actionId == surveyActionYes) {
        onSurveyResponse?.call(true);
      } else if (response.actionId == surveyActionNo) {
        onSurveyResponse?.call(false);
      } else if (response.payload == surveyPayload ||
          response.payload == logPayload) {
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
      actions: [
        AndroidNotificationAction(
          surveyActionYes,
          'Yes',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          surveyActionNo,
          'No',
          showsUserInterface: false,
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
    );
    const darwin = DarwinNotificationDetails();
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }
}
