import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water_intake/models/reminder_model.dart';
import 'package:water_intake/route/route.dart';
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/utils/local_storage.dart';
import 'package:water_intake/view/walkthrough/controller/walkthrough_controller.dart';

class ReminderController extends GetxController {
  // Reminders list using the model
  var reminders = <ReminderModel>[].obs;

  var selectedHour = 9.obs;
  var selectedMinute = 0.obs;
  var isAm = true.obs;

  // Time format setting
  var is12HourFormat = true.obs;

  late FixedExtentScrollController hourScrollController;
  late FixedExtentScrollController minuteScrollController;
  late FixedExtentScrollController amPmScrollController;

  @override
  void onInit() {
    super.onInit();
    _fetchReminders();
    _initTimePickers();
  }

  void _initTimePickers() {
    final now = DateTime.now();
    if (is12HourFormat.value) {
      int hour = now.hour;
      isAm.value = hour < 12;
      selectedHour.value = hour % 12 == 0 ? 12 : hour % 12;
    } else {
      selectedHour.value = now.hour;
    }
    selectedMinute.value = now.minute;

    hourScrollController = FixedExtentScrollController(initialItem: is12HourFormat.value ? selectedHour.value - 1 : selectedHour.value);
    minuteScrollController = FixedExtentScrollController(initialItem: selectedMinute.value);
    amPmScrollController = FixedExtentScrollController(initialItem: isAm.value ? 0 : 1);
  }

  @override
  void onClose() {
    hourScrollController.dispose();
    minuteScrollController.dispose();
    amPmScrollController.dispose();
    super.onClose();
  }

  Future<void> _fetchReminders() async {
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        var snapshot = await FirebaseService().firestore
            .collection('users')
            .doc(uid)
            .collection('reminders')
            .orderBy('createdAt', descending: false)
            .get();

        if (snapshot.docs.isNotEmpty) {
          reminders.assignAll(snapshot.docs.map((doc) => ReminderModel.fromMap(doc.data(), doc.id)).toList());
        } else {
          _addDefaultReminder();
        }
      } else {
        _addDefaultReminder();
      }
    } catch (e) {
      debugPrint("Error fetching reminders: $e");
      _addDefaultReminder();
    }
  }

  void _addDefaultReminder() {
    reminders.assignAll([
      ReminderModel(
        id: 'temp_default',
        uid: FirebaseService().auth.currentUser?.uid ?? '',
        timeRange: AppString.defaultTimeRange.tr,
        interval: AppString.everyTwoHours.tr,
        isActive: true,
        isCustom: false,
      ),
    ]);
  }

  void toggleReminder(int index, bool value) async {
    reminders[index].isActive.obs.value = value; // This is a bit tricky with GetX if not using Rx properties in model
    // Better way to trigger UI:
    var reminder = reminders[index];
    reminders[index] = ReminderModel(
      id: reminder.id,
      uid: reminder.uid,
      timeRange: reminder.timeRange,
      interval: reminder.interval,
      isActive: value,
      isCustom: reminder.isCustom,
    );

    // Sync to Firestore
    String? uid = await FirebaseService().getUserId();
    if (uid != null && !reminder.id.startsWith('temp_')) {
      await FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc(reminder.id).update({'isActive': value});
    }
  }

  void toggleSwipe(int index, bool isSwiped) {
    reminders[index].isSwiped.value = isSwiped;
  }

  Future<void> saveReminder() async {
    String hourStr = is12HourFormat.value ? selectedHour.value.toString() : selectedHour.value.toString().padLeft(2, '0');
    String minuteStr = selectedMinute.value.toString().padLeft(2, '0');
    String amPmStr = is12HourFormat.value ? (isAm.value ? ' AM' : ' PM') : '';

    String timeStr = '$hourStr:$minuteStr$amPmStr';

    String? uid = await FirebaseService().getUserId();
    if (uid != null) {
      var docRef = FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc();

      ReminderModel newReminder = ReminderModel(id: docRef.id, uid: uid, timeRange: timeStr, interval: "", isActive: true, isCustom: true);

      await docRef.set(newReminder.toMap());
      reminders.add(newReminder);
    } else {
      // Local only if not logged in (fallback)
      reminders.add(
        ReminderModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          uid: '',
          timeRange: timeStr,
          interval: AppString.everyTwoHours.tr,
          isActive: true,
          isCustom: true,
        ),
      );
    }
    Get.back();
  }

  Future<void> deleteReminder(int index) async {
    var reminder = reminders[index];
    reminders.removeAt(index);

    String? uid = await FirebaseService().getUserId();
    if (uid != null && !reminder.id.startsWith('temp_')) {
      await FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc(reminder.id).delete();
    }
  }

  Future<void> completeSetup() async {
    await LocalStorage.setSetupComplete(true);

    // Sync the default reminder if it hasn't been saved yet (fallback)
    String? uid = await FirebaseService().getUserId();
    if (uid != null) {
      for (var reminder in reminders) {
        if (reminder.id == 'temp_default' && !reminder.isCustom) {
          var docRef = FirebaseService().firestore.collection('users').doc(uid).collection('reminders').doc();

          ReminderModel defaultReminderToSave = ReminderModel(
            id: docRef.id,
            uid: uid,
            timeRange: reminder.timeRange,
            interval: reminder.interval,
            isActive: reminder.isActive,
            isCustom: reminder.isCustom,
          );

          await docRef.set(defaultReminderToSave.toMap());
        }
      }
    }

    if (Get.isRegistered<WalkthroughController>()) {
      Get.delete<WalkthroughController>(force: true);
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }
}
