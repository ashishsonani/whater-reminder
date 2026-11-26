import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water_intake/models/reminder_model.dart';
import 'package:water_intake/route/route.dart';
import 'package:water_intake/services/notification_service.dart';
import 'package:water_intake/services/reminder_store.dart';
import 'package:water_intake/utils/local_storage.dart';
import 'package:water_intake/view/walkthrough/controller/walkthrough_controller.dart';

class ReminderController extends GetxController {
  final _store = ReminderStore.instance;
  StreamSubscription<void>? _subscription;

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
    _subscription = _store.changes.listen((_) => _fetchReminders());
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

    hourScrollController = FixedExtentScrollController(
      initialItem: is12HourFormat.value
          ? selectedHour.value - 1
          : selectedHour.value,
    );
    minuteScrollController = FixedExtentScrollController(
      initialItem: selectedMinute.value,
    );
    amPmScrollController = FixedExtentScrollController(
      initialItem: isAm.value ? 0 : 1,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    hourScrollController.dispose();
    minuteScrollController.dispose();
    amPmScrollController.dispose();
    super.onClose();
  }

  Future<void> _fetchReminders() async {
    final saved = await _store.read();
    if (isClosed) return;
    reminders.assignAll(
      saved.map(
        (reminder) => ReminderModel(
          id: reminder.id!,
          timeRange: reminder.time ?? '',
          interval: reminder.interval ?? '',
          isActive: reminder.isEnabled ?? true,
          isCustom: reminder.isCustom ?? false,
        ),
      ),
    );
  }

  Future<void> toggleReminder(int index, bool value) =>
      _store.toggle(reminders[index].id, value);

  void toggleSwipe(int index, bool isSwiped) {
    reminders[index].isSwiped.value = isSwiped;
  }

  Future<void> saveReminder() async {
    String hourStr = is12HourFormat.value
        ? selectedHour.value.toString()
        : selectedHour.value.toString().padLeft(2, '0');
    String minuteStr = selectedMinute.value.toString().padLeft(2, '0');
    String amPmStr = is12HourFormat.value ? (isAm.value ? ' AM' : ' PM') : '';

    String timeStr = '$hourStr:$minuteStr$amPmStr';

    await _store.add(timeStr);
    Get.back();
  }

  Future<void> deleteReminder(int index) => _store.delete(reminders[index].id);

  Future<void> completeSetup() async {
    await LocalStorage.setSetupComplete(true);
    await NotificationService().refreshReminderSchedule();

    if (Get.isRegistered<WalkthroughController>()) {
      Get.delete<WalkthroughController>(force: true);
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }
}
