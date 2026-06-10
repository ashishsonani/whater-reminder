import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ReminderModel {
  final String id;
  final String uid;
  final String timeRange;
  final String interval;
  final bool isActive;
  final bool isCustom;
  final RxBool isSwiped = false.obs; // UI state

  ReminderModel({
    required this.id,
    required this.uid,
    required this.timeRange,
    required this.interval,
    required this.isActive,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'timeRange': timeRange,
      'interval': interval,
      'isActive': isActive,
      'isCustom': isCustom,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map, String id) {
    return ReminderModel(
      id: id,
      uid: map['uid'] ?? '',
      timeRange: map['timeRange'] ?? '',
      interval: map['interval'] ?? '',
      isActive: map['isActive'] ?? true,
      isCustom: map['isCustom'] ?? false,
    );
  }
}
