import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/view/account/screen/reminder/model/reminder_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  StreamSubscription? _remindersSubscription;
  StreamSubscription? _userSettingsSubscription;
  bool _isRescheduling = false;

  Future<void> init() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    // 0. Cancel all notifications on app open
    await cancelAllNotifications();

    // 1. Initialize Timezones
    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      log('Timezone successfully initialized to: ${timeZoneInfo.identifier}');
    } catch (e) {
      log('Failed to get local timezone: $e. Using UTC.');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    // 2. Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else {
      log('User declined or has not accepted permission');
    }

    // Request Android 13+ local notification permission
    try {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      log('Error requesting Android local notification permission: $e');
    }

    // Request exact alarm permission for Android 14+
    try {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      log('Error requesting exact alarm permission: $e');
    }

    // 2. Initialize local notifications for foreground messages
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          log('Notification clicked with payload: ${details.payload}');
        }

        if (details.actionId == 'action_drink_250') {
          _handleDrinkAction();
        } else if (details.actionId == 'action_snooze_10') {
          _handleSnoozeAction();
        }
      },
      settings: initializationSettings,
    );

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground message: ${message.data}');
      _showLocalNotification(message);
    });

    // 5. Get token and store in Firestore
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        log('FCM Token: $token');
        await FirebaseService().updateFcmToken(token);
      }
    } catch (e) {
      log('Error getting FCM token: $e');
    }

    // 6. Listen to Auth state changes to setup Firestore listeners for reminders
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        log('NotificationService: User logged in, setting up reminders listener. UID: ${user.uid}');
        _setupRemindersListener(user.uid);
      } else {
        log('NotificationService: User logged out, cancelling reminders listener.');
        _cancelRemindersListener();
      }
    });
  }

  Future<void> _handleDrinkAction() async {
    log('Handling Drink 250ml action...');
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid == null) return;

      final now = DateTime.now();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final recordId = now.millisecondsSinceEpoch.toString();

      final summaryRef = FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(todayStr);

      final summaryDoc = await summaryRef.get();
      int currentIntake = 0;
      int targetIntake = 0; // Default fallback

      if (summaryDoc.exists) {
        currentIntake = summaryDoc.data()?['currentIntakeValue'];
        targetIntake = summaryDoc.data()?['targetIntakeValue'];
      }

      int newIntake = currentIntake + 250;

      // Add individual record
      await summaryRef.collection('daily_records').doc(recordId).set({
        'id': recordId,
        'amount': 250,
        'type': 'Glass',
        'createdAt': Timestamp.fromDate(now),
        'currentIntakeAtTime': newIntake,
        'targetIntakeAtTime': targetIntake,
        'userId': uid,
      });

      // Update summary
      await summaryRef.set({'currentIntakeValue': newIntake, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      log('Water intake updated via notification action');
    } catch (e) {
      log('Error handling drink action: $e');
    }
  }

  Future<void> _handleSnoozeAction() async {
    log('Handling Snooze 10 min action (Cloud Integration)...');
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid == null) return;

      // Calculate time for 10 minutes from now
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));

      // Format as "H:MM AM/PM" to match Cloud Function expectations
      int hour = snoozeTime.hour;
      int minute = snoozeTime.minute;
      String ampm = hour >= 12 ? 'PM' : 'AM';
      int hour12 = hour % 12 == 0 ? 12 : hour % 12;
      String timeStr = "$hour12:${minute.toString().padLeft(2, '0')} $ampm";

      final reminderId = "snooze_${DateTime.now().millisecondsSinceEpoch}";

      await FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc(reminderId).set({
        'id': reminderId,
        'uid': uid,
        'timeRange': timeStr,
        'interval': '10 min',
        'isActive': true,
        'isCustom': true,
        'isSnooze': true, // Tag it as a snooze reminder
        'createdAt': FieldValue.serverTimestamp(),
      });

      log('Snooze reminder set for $timeStr in Firestore');
    } catch (e) {
      log('Error setting snooze reminder: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
    log('All local notifications cancelled');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Check if notifications are globally enabled
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!isEnabled) {
        log('Suppressing foreground notification as global toggle is OFF');
        return;
      }
    } catch (e) {
      log('Error checking notification settings: $e');
    }

    final title = message.data['title'] ?? 'Stay Hydrated! 💧';
    final body = message.data['body'] ?? 'Time for a glass of water.';
    final bool hasActions = message.data['type'] == 'reminder_with_actions';

    final String drinkText = message.data['drink_text'] ?? 'Drink 250ml';
    final String snoozeText = message.data['snooze_text'] ?? 'Snooze 10 min';

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'water_intake_channel',
      'Water Intake Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      sound: const RawResourceAndroidNotificationSound('water'),
      actions: hasActions
          ? <AndroidNotificationAction>[
              AndroidNotificationAction('action_drink_250', drinkText, showsUserInterface: true, cancelNotification: true),
              AndroidNotificationAction('action_snooze_10', snoozeText, showsUserInterface: true, cancelNotification: true),
            ]
          : null,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  void _setupRemindersListener(String uid) {
    _cancelRemindersListener();

    // Listen to user's global notification toggle in Firestore
    _userSettingsSubscription = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((userDoc) async {
      if (userDoc.exists) {
        final isEnabled = userDoc.data()?['isNotificationEnabled'] ?? true;
        
        // Sync with SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('notifications_enabled', isEnabled);
        } catch (e) {
          log('Error syncing settings to SharedPreferences: $e');
        }

        _rescheduleWithLatestData(uid, isEnabled);
      }
    });

    // Listen to user's reminders subcollection in Firestore
    _remindersSubscription = FirebaseFirestore.instance.collection('users').doc(uid).collection('reminders').snapshots().listen((
      remindersSnapshot,
    ) {
      _rescheduleWithLatestData(uid, null);
    });
  }

  void _cancelRemindersListener() {
    _remindersSubscription?.cancel();
    _userSettingsSubscription?.cancel();
    _remindersSubscription = null;
    _userSettingsSubscription = null;
  }

  Future<void> _rescheduleWithLatestData(String uid, bool? globalEnabled) async {
    if (_isRescheduling) return;
    _isRescheduling = true;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final isEnabled = globalEnabled ?? (userDoc.data()?['isNotificationEnabled'] ?? true);
      final String? language = userDoc.data()?['language'];

      final remindersSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('reminders').get();

      final reminderList = remindersSnapshot.docs.map((doc) => Reminder.fromJson(doc.data())).toList();

      await rescheduleAllReminders(reminderList, isEnabled, language);
    } catch (e) {
      log('Error in rescheduleWithLatestData: $e');
    } finally {
      _isRescheduling = false;
    }
  }

  Future<void> rescheduleAllReminders(List<Reminder> reminders, bool isGlobalEnabled, String? language) async {
    await cancelAllNotifications();

    if (!isGlobalEnabled) {
      log('Global notifications are disabled. All local reminders are cancelled.');
      return;
    }

    final texts = getNotificationStrings(language);

    log('Scheduling ${reminders.length} local reminders for language: $language...');
    for (final reminder in reminders) {
      if (reminder.isEnabled != true) continue;

      final times = parseReminderTimes(reminder.time, reminder.interval);
      if (times.isEmpty) continue;

      for (int i = 0; i < times.length; i++) {
        final timeOfDay = times[i];
        final int baseId = (reminder.id ?? '').hashCode.abs() % 10000000;
        final int id = (baseId * 100 + i) % 2147483647;

        await scheduleReminderNotification(
          id: id,
          hour: timeOfDay.hour,
          minute: timeOfDay.minute,
          isSnooze: reminder.isSnooze == true,
          title: texts['title'] ?? 'Stay Hydrated! 💧',
          body: texts['body'] ?? 'Time for a glass of water.',
          drinkText: texts['drink'] ?? 'Drink 250ml',
          snoozeText: texts['snooze'] ?? 'Snooze 10 min',
        );
      }
    }
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required int hour,
    required int minute,
    required bool isSnooze,
    required String title,
    required String body,
    required String drinkText,
    required String snoozeText,
  }) async {
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'water_intake_channel',
        'Water Intake Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        sound: const RawResourceAndroidNotificationSound('water'),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('action_drink_250', drinkText, showsUserInterface: true, cancelNotification: true),
          AndroidNotificationAction('action_snooze_10', snoozeText, showsUserInterface: true, cancelNotification: true),
        ],
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

      if (isSnooze) {
        // One-time schedule
        await _localNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'snooze_reminder',
        );
        log('Snoozed notification scheduled ID $id at $scheduledDate in user timezone');
      } else {
        // Daily recurring schedule
        await _localNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'scheduled_reminder',
        );
        log(
          'Daily notification scheduled ID $id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (Zoned local time: $scheduledDate)',
        );
      }
    } catch (e) {
      log('Error scheduling notification ID $id: $e');
    }
  }

  Map<String, String> getNotificationStrings(String? language) {
    final lang = language?.toLowerCase() ?? 'english';

    if (lang.contains('türkçe') || lang.contains('turkish')) {
      return {'title': 'Hidrasyon Zamanı! 💧', 'body': 'Bir bardak su içme vakti.', 'drink': '250ml İç', 'snooze': '10 Dk Ertele'};
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
      return {'title': 'حافظ على رطوبة جسمك! 💧', 'body': 'حان الوقت لشرب كوب من الماء.', 'drink': 'شرب 250 مل', 'snooze': 'غفوة 10 دقائق'};
    } else if (lang.contains('اردو') || lang.contains('urdu')) {
      return {
        'title': 'ہائیڈریٹڈ رہیں! 💧',
        'body': 'ایک گلاس پانی پینے کا وقت۔',
        'drink': '250 ملی لیٹر پییں',
        'snooze': '10 منٹ بعد یاد دلائیں',
      };
    } else {
      return {'title': 'Stay Hydrated! 💧', 'body': 'Time for a glass of water.', 'drink': 'Drink 250ml', 'snooze': 'Snooze 10 min'};
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

          final adjustedEndMinutes = (endMinutes < currentMinutes) ? (endMinutes + 24 * 60) : endMinutes;

          while (currentMinutes <= adjustedEndMinutes) {
            final h = (currentMinutes ~/ 60) % 24;
            final m = currentMinutes % 60;
            times.add(TimeOfDay(hour: h, minute: m));
            currentMinutes += intervalMinutes;
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
        final ampmMatch = RegExp(r'(AM|PM)', caseSensitive: false).firstMatch(cleanStr);
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

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

// Handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    log('Handling background message: ${message.messageId}');

    // Check global toggle in background isolate
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!isEnabled) {
        log('Suppressing background notification as global toggle is OFF');
        return;
      }
    } catch (e) {
      log('Error checking settings in background: $e');
    }

    // We must initialize the plugin in the background isolate
    final FlutterLocalNotificationsPlugin localPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await localPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handled when app is opened
      },
    );

    final String? type = message.data['type'];
    final bool hasActions = type == 'reminder_with_actions';

    final title = message.data['title'] ?? 'Stay Hydrated! 💧';
    final body = message.data['body'] ?? 'Time for a glass of water.';

    final String drinkText = message.data['drink_text'] ?? 'Drink 250ml';
    final String snoozeText = message.data['snooze_text'] ?? 'Snooze 10 min';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_intake_channel',
      'Water Intake Notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('water'),
      actions: hasActions
          ? <AndroidNotificationAction>[
              AndroidNotificationAction('action_drink_250', drinkText, showsUserInterface: true, cancelNotification: true),
              AndroidNotificationAction('action_snooze_10', snoozeText, showsUserInterface: true, cancelNotification: true),
            ]
          : null,
    );

    int notifId = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch).abs();
    // Cap it to 32-bit max to be safe
    if (notifId > 2147483647) {
      notifId = notifId % 2147483647;
    }

    log('Showing local notification with id: $notifId, title: $title, body: $body');

    await localPlugin.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: message.data.toString(),
    );
    log('Local notification displayed successfully from background handler');
  } catch (e, stackTrace) {
    log('Fatal error in background handler: $e\n$stackTrace');
  }
}
