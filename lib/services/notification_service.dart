import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:water_intake/services/water_log_store.dart';
import 'package:water_intake/services/reminder_store.dart';
import 'package:water_intake/services/reminder_schedule.dart';
import 'package:water_intake/utils/local_storage.dart';
import 'package:water_intake/view/account/screen/reminder/model/reminder_model.dart';

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _reminders = ReminderStore.instance;
  Future<void>? _initialization;
  Future<void> _scheduleQueue = Future.value();
  bool _scheduleQueued = false;
  String? _language;

  Future<void> init() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (error) {
      log('Could not load device timezone: $error');
    }

    await _localNotificationsPlugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              'water_reminder',
              actions: [
                DarwinNotificationAction.plain(
                  'action_drink_250',
                  'Drink 250ml',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  'action_snooze_10',
                  'Snooze 10 min',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('selected_language');
    final launch = await _localNotificationsPlugin
        .getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      await _handleResponse(response);
    }

    WidgetsBinding.instance.addObserver(this);
    _reminders.changes.listen((_) => _queueReschedule());
    WaterLogStore.instance.changes.listen((_) => _queueReschedule());
    _queueReschedule();
    final legacyUid = await LocalStorage.getUserId();
    if (legacyUid != null) unawaited(_importLegacyReminders(legacyUid));
  }

  Future<void> _importLegacyReminders(String uid) async {
    try {
      if (!await _reminders.needsImport()) return;
      final user = FirebaseFirestore.instance.collection('users').doc(uid);
      const source = GetOptions(source: Source.server);
      final profile = await user.get(source);
      final reminders = await user.collection('reminders').get(source);
      await _reminders.importLegacy(
        reminders.docs
            .map((doc) => Reminder.fromJson({...doc.data(), 'id': doc.id}))
            .toList(),
        enabled: profile.data()?['isNotificationEnabled'] != false,
      );
    } catch (error) {
      log('Error importing legacy reminders: $error');
    }
  }

  Future<void> requestPermissions() async {
    try {
      await init();
      final android = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      final ios = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (error) {
      log('Error requesting notification permissions: $error');
    }
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    try {
      final now = DateTime.now();
      if (response.actionId == 'action_drink_250') {
        await WaterLogStore.instance.add(now, 250, 'Glass');
      } else if (response.actionId == 'action_snooze_10') {
        if (!await _reminders.isEnabled() || await _skipToday(now)) return;
        await _schedule(
          2147483647,
          tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
          payload: 'local_snooze',
        );
      }
    } catch (error) {
      log('Error handling local notification action: $error');
    }
  }

  Future<void> refreshReminderSchedule() async {
    await init();
    _queueReschedule();
    await _scheduleQueue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _queueReschedule();
  }

  Future<bool> _skipToday(DateTime now) async {
    if (await _reminders.isPausedOn(now)) return true;
    if (!await _reminders.stopsAtGoal()) return false;
    final day = (await WaterLogStore.instance
        .read())[WaterLogStore.dateKey(now)];
    return day?.goalMet ?? false;
  }

  void _queueReschedule() {
    if (_scheduleQueued) return;
    _scheduleQueued = true;
    _scheduleQueue = _scheduleQueue
        .then((_) async {
          _scheduleQueued = false;
          if (!await _reminders.isEnabled()) {
            await _localNotificationsPlugin.cancelAll();
            return;
          }
          if (!await LocalStorage.isSetupComplete()) return;

          final prefs = await SharedPreferences.getInstance();
          final now = tz.TZDateTime.now(tz.local);
          final skipToday = await _skipToday(now);
          final weekdaysByMinute = <int, Set<int>>{};
          for (final reminder in await _reminders.read()) {
            if (reminder.isEnabled != true) continue;
            for (final time in parseReminderTimes(
              reminder.time,
              reminder.interval,
            )) {
              (weekdaysByMinute[time.hour * 60 + time.minute] ??= {}).addAll(
                reminder.days.days,
              );
            }
          }
          final planned = planReminderSlots(
            weekdaysByMinute,
            now,
            skipToday: skipToday,
          );
          // iOS limits pending requests. Keep the earliest slots and leave room for snooze.
          final desired = {
            for (final slot in Platform.isIOS ? planned.take(63) : planned)
              slot.id: slot,
          };
          _language = prefs.getString('selected_language');
          final texts = getNotificationStrings(_language);
          final scheduled = <int>{};
          for (final pending
              in await _localNotificationsPlugin
                  .pendingNotificationRequests()) {
            if (pending.payload == 'local_snooze' && !skipToday) continue;
            final slot = desired[pending.id];
            if (slot != null &&
                pending.payload == 'reminder:${slot.key}' &&
                pending.title == texts['title'] &&
                pending.body == texts['body']) {
              scheduled.add(pending.id);
            } else {
              await _localNotificationsPlugin.cancel(id: pending.id);
            }
          }
          for (final slot in desired.values) {
            if (scheduled.contains(slot.id)) continue;
            try {
              await _schedule(
                slot.id,
                slot.date,
                repeat: slot.repeat,
                payload: 'reminder:${slot.key}',
              );
            } catch (error) {
              log('Error scheduling local reminder: $error');
            }
          }
        })
        .catchError((Object error) {
          log('Error refreshing local reminder schedule: $error');
        });
  }

  Future<void> _schedule(
    int id,
    tz.TZDateTime date, {
    DateTimeComponents? repeat,
    required String payload,
  }) async {
    final texts = getNotificationStrings(_language);
    final android = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: texts['title'],
      body: texts['body'],
      scheduledDate: date,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'water_intake_channel',
          'Water Intake Notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound('water'),
          actions: [
            AndroidNotificationAction(
              'action_drink_250',
              texts['drink']!,
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'action_snooze_10',
              texts['snooze']!,
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'water_reminder',
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: repeat,
      payload: payload,
    );
  }

  Map<String, String> getNotificationStrings(String? language) {
    final lang = language?.toLowerCase() ?? 'english';

    if (lang.contains('türkçe') || lang.contains('turkish')) {
      return {
        'title': 'Hidrasyon Zamanı! 💧',
        'body': 'Bir bardak su içme vakti.',
        'drink': '250ml İç',
        'snooze': '10 Dk Ertele',
      };
    } else if (lang.contains('español') || lang.contains('spanish')) {
      return {
        'title': '¡Mantente Hidratado! 💧',
        'body': 'Hora de beber un vaso de agua.',
        'drink': 'Beber 250ml',
        'snooze': 'Posponer 10 min',
      };
    } else if (lang.contains('deutsch') || lang.contains('german')) {
      return {
        'title': 'Bleib Hydratisiert! 💧',
        'body': 'Zeit für ein Glas Wasser.',
        'drink': '250ml Trinken',
        'snooze': 'Schlummern 10 Min.',
      };
    } else if (lang.contains('français') || lang.contains('french')) {
      return {
        'title': 'Restez Hydraté ! 💧',
        'body': 'C\'est l\'heure de boire un verre d\'eau.',
        'drink': 'Boire 250ml',
        'snooze': 'Rappeler dans 10 min',
      };
    } else if (lang.contains('हिन्दी') || lang.contains('hindi')) {
      return {
        'title': 'हाइड्रेटेड रहें! 💧',
        'body': 'एक गिलास पानी पीने का समय।',
        'drink': '250 मिलीलीटर पिएं',
        'snooze': '10 मिनट बाद याद दिलाएं',
      };
    } else if (lang.contains('فارسی') || lang.contains('persian')) {
      return {
        'title': 'هیدراته بمانید! 💧',
        'body': 'زمان نوشیدن یک لیوان آب.',
        'drink': 'نوشیدن 250 میلی‌لیتر',
        'snooze': '10 دقیقه به تعویق انداختن',
      };
    } else if (lang.contains('العربية') || lang.contains('arabic')) {
      return {
        'title': 'حافظ على رطوبة جسمك! 💧',
        'body': 'حان الوقت لشرب كوب من الماء.',
        'drink': 'شرب 250 مل',
        'snooze': 'غفوة 10 دقائق',
      };
    } else if (lang.contains('اردو') || lang.contains('urdu')) {
      return {
        'title': 'ہائیڈریٹڈ رہیں! 💧',
        'body': 'ایک گلاس پانی پینے کا وقت۔',
        'drink': '250 ملی لیٹر پییں',
        'snooze': '10 منٹ بعد یاد دلائیں',
      };
    } else {
      return {
        'title': 'Stay Hydrated! 💧',
        'body': 'Time for a glass of water.',
        'drink': 'Drink 250ml',
        'snooze': 'Snooze 10 min',
      };
    }
  }

  List<TimeOfDay> parseReminderTimes(String? timeStr, String? intervalStr) {
    if (timeStr == null || timeStr.isEmpty) return [];

    final cleanStr = timeStr.trim();
    final rangeSeparator = RegExp(r'[–-]|to');

    if (rangeSeparator.hasMatch(cleanStr)) {
      final parts = cleanStr.split(rangeSeparator);
      if (parts.length >= 2) {
        final startTime = parseSingleTime(parts[0]);
        final endTime = parseSingleTime(parts[1]);
        if (startTime != null && endTime != null) {
          int intervalMinutes = 120; // Default: 2 hours (120 minutes)
          if (intervalStr != null) {
            final intervalLower = intervalStr.toLowerCase();
            if (intervalLower.contains('hour')) {
              final numMatch = RegExp(r'\d+').firstMatch(intervalLower);
              if (numMatch != null) {
                intervalMinutes = int.parse(numMatch.group(0)!) * 60;
              }
            } else if (intervalLower.contains('min')) {
              final numMatch = RegExp(r'\d+').firstMatch(intervalLower);
              if (numMatch != null) {
                intervalMinutes = int.parse(numMatch.group(0)!);
              }
            }
          }

          final List<TimeOfDay> times = [];
          int currentMinutes = startTime.hour * 60 + startTime.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;

          final adjustedEndMinutes = (endMinutes < currentMinutes)
              ? (endMinutes + 24 * 60)
              : endMinutes;

          while (currentMinutes <= adjustedEndMinutes) {
            final h = (currentMinutes ~/ 60) % 24;
            final m = currentMinutes % 60;
            times.add(TimeOfDay(hour: h, minute: m));
            currentMinutes += intervalMinutes > 0 ? intervalMinutes : 120;
          }
          return times;
        }
      }
    }

    final singleTime = parseSingleTime(cleanStr);
    return singleTime != null ? [singleTime] : [];
  }

  TimeOfDay? parseSingleTime(String timeStr) {
    try {
      final cleanStr = timeStr.trim();
      final parts = cleanStr.split(RegExp(r'\s+'));
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = 0;
      if (timeParts.length > 1) {
        minute = int.parse(timeParts[1]);
      }

      if (parts.length > 1) {
        final marker = parts[1].toUpperCase();
        if (marker == 'PM' && hour < 12) {
          hour += 12;
        } else if (marker == 'AM' && hour == 12) {
          hour = 0;
        }
      } else {
        final ampmMatch = RegExp(
          r'(AM|PM)',
          caseSensitive: false,
        ).firstMatch(cleanStr);
        if (ampmMatch != null) {
          final marker = ampmMatch.group(0)!.toUpperCase();
          if (marker == 'PM' && hour < 12) {
            hour += 12;
          } else if (marker == 'AM' && hour == 12) {
            hour = 0;
          }
        }
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      log('Error parsing single time: $timeStr, error: $e');
      return null;
    }
  }

  TimeOfDay? parseReminderTime(String? timeStr) {
    return parseSingleTime(timeStr ?? '');
  }
}
