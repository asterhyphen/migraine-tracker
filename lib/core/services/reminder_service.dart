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
  static const _dailyReminderId = 701;
  static const _staleReminderId = 702;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _handledLaunchNotification = false;

  Future<void> initialize({void Function()? onLogRequested}) async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == logPayload) {
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
        response?.payload == logPayload) {
      _handledLaunchNotification = true;
      onLogRequested?.call();
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
  }) async {
    await initialize();
    await _notifications.cancel(id: _dailyReminderId);
    await _notifications.cancel(id: _staleReminderId);

    if (settings.dailyReminderEnabled) {
      await _scheduleDaily(settings);
    }

    if (settings.staleReminderEnabled) {
      await _scheduleStaleReminder(settings, entries);
    }
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    await _notifications.cancel(id: _dailyReminderId);
    await _notifications.cancel(id: _staleReminderId);
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
  }

  Future<void> _scheduleDaily(AppSettings settings) async {
    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: 'Time to log your symptoms',
      body: settings.dailyReminderMessage,
      scheduledDate: _nextTime(settings.reminderHour, settings.reminderMinute),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: logPayload,
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

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
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
}
