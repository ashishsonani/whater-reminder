import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:water_intake/services/reminder_store.dart';

import '../model/reminder_model.dart';

class DrinkRemindersController extends GetxController {
  var isReminderEnabled = true.obs;
  var isLoading = false.obs;
  var reminders = <Reminder>[].obs;

  final _store = ReminderStore.instance;
  StreamSubscription<void>? _subscription;

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
    _subscription = _store.changes.listen((_) => _loadReminders());
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final saved = await _store.read();
    final enabled = await _store.isEnabled();
    if (isClosed) return;
    reminders.assignAll(saved.reversed);
    isReminderEnabled.value = enabled;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    hourScrollController.dispose();
    minuteScrollController.dispose();
    amPmScrollController.dispose();
    super.onClose();
  }

  Future<void> toggleGlobalReminders(bool value) => _store.setEnabled(value);

  Future<void> toggleReminder(int index) async {
    final reminder = reminders[index];
    await _store.toggle(reminder.id, reminder.isEnabled != true);
  }

  Future<bool> addReminder(String time, {required String amPm}) async {
    final formattedTime = amPm.isEmpty ? time : '$time ${amPm.toUpperCase()}';
    if (reminders.any((reminder) => reminder.time == formattedTime)) {
      return false;
    }

    isLoading.value = true;
    try {
      await _store.add(formattedTime);
      return true;
    } catch (error) {
      log('Error adding reminder: $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteReminder(int index) => _store.delete(reminders[index].id);
}
