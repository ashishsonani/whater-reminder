import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/view/account/controller/account_controller.dart';

import '../model/reminder_model.dart';

class DrinkRemindersController extends GetxController {
  var isReminderEnabled = true.obs;
  var isLoading = false.obs;
  var reminders = <Reminder>[].obs;

  // Picker states
  var selectedHour = 9.obs;
  var selectedMinute = 0.obs;
  var isAm = true.obs;
  var is12HourFormat = true.obs;

  late FixedExtentScrollController hourScrollController;
  late FixedExtentScrollController minuteScrollController;
  late FixedExtentScrollController amPmScrollController;

  @override
  void onInit() {
    super.onInit();
    hourScrollController = FixedExtentScrollController(initialItem: 8);
    minuteScrollController = FixedExtentScrollController(initialItem: 0);
    amPmScrollController = FixedExtentScrollController(initialItem: 0);
    _initReminderStream();
  }

  void _initReminderStream() async {
    String? uid = await FirebaseService().getUserId();
    if (uid == null) return;

    // Sync master toggle with AccountController/Firestore
    try {
      final accountController = Get.find<AccountController>();
      isReminderEnabled.value = accountController.isNotificationEnabled.value;
    } catch (_) {
      // Fallback: Fetch directly from Firestore
      final doc = await FirebaseService().firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('isNotificationEnabled')) {
        isReminderEnabled.value = doc.data()!['isNotificationEnabled'];
      }
    }

    FirebaseService().firestore
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          reminders.assignAll(snapshot.docs.map((doc) => Reminder.fromJson(doc.data())).toList());
        });
  }

  @override
  void onClose() {
    hourScrollController.dispose();
    minuteScrollController.dispose();
    amPmScrollController.dispose();
    super.onClose();
  }

  Future<void> toggleGlobalReminders(bool value) async {
    isReminderEnabled.value = value;
    
    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
    } catch (e) {
      log("Error saving global reminder setting: $e");
    }

    // Sync with AccountController if active
    try {
      Get.find<AccountController>().isNotificationEnabled.value = value;
    } catch (_) {}

    // Update Firestore for Cloud Function
    await FirebaseService().updateNotificationSettings(value);
  }

  Future<void> toggleReminder(int index) async {
    final reminder = reminders[index];
    if (reminder.id == null) return;

    String? uid = await FirebaseService().getUserId();
    if (uid == null) return;

    await FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc(reminder.id).update({
      'isActive': !(reminder.isEnabled ?? false),
    });
  }

  Future<bool> addReminder(String time, {required String amPm}) async {
    String formattedTime = "$time ${amPm.toUpperCase()}";
    if (reminders.any((r) => r.time == formattedTime)) {
      return false; // Time already exists
    }

    String? uid = await FirebaseService().getUserId();
    if (uid == null) return false;

    isLoading.value = true;
    try {
      final docRef = FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc();

      final reminder = Reminder(id: docRef.id, time: formattedTime, isEnabled: true, isCustom: true, createdAt: DateTime.now());

      await docRef.set(reminder.toJson());
      return true;
    } catch (e) {
      log("Error adding reminder: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteReminder(int index) async {
    final reminder = reminders[index];
    if (reminder.id == null) return;

    String? uid = await FirebaseService().getUserId();
    if (uid == null) return;

    try {
      await FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc(reminder.id).delete();
    } catch (e) {
      log("Error deleting reminder: $e");
    }
  }
}
