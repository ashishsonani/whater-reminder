import 'package:get/get.dart';

class ReminderModel {
  final String id;
  final String timeRange;
  final String interval;
  final bool isActive;
  final bool isCustom;
  final RxBool isSwiped = false.obs; // UI state

  ReminderModel({
    required this.id,
    required this.timeRange,
    required this.interval,
    required this.isActive,
    this.isCustom = false,
  });
}
