import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String activityLevel;
  final int age;
  final String bedTime;
  final String climate;
  final String gender;
  final bool isKg;
  final bool isMl;
  final DateTime? updatedAt;
  final String wakeUpTime;
  final int waterGoal;
  final int weight;
  final int currentStreak;
  final int longestStreak;
  final String lastStreakDate;
  final String timeFormat;
  final List<String> awards;
  final List<String> celebratedAwards;
  final String fcmToken;
  final bool isPremium;

  UserModel({
    required this.uid,
    required this.activityLevel,
    required this.age,
    required this.bedTime,
    required this.climate,
    required this.gender,
    required this.isKg,
    required this.isMl,
    this.updatedAt,
    required this.wakeUpTime,
    required this.waterGoal,
    required this.weight,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakDate = '',
    this.timeFormat = '12-hour',
    this.awards = const [],
    this.celebratedAwards = const [],
    this.fcmToken = '',
    this.isPremium = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid'] ?? documentId,
      activityLevel: map['activityLevel'] ?? '',
      age: map['age']?.toInt() ?? 0,
      bedTime: map['bedTime'] ?? '',
      climate: map['climate'] ?? '',
      gender: map['gender'] ?? '',
      isKg: map['isKg'] ?? true,
      isMl: map['isMl'] ?? true,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      wakeUpTime: map['wakeUpTime'] ?? '',
      waterGoal: map['waterGoal']?.toInt() ?? 0,
      weight: map['weight']?.toInt() ?? 0,
      currentStreak: map['currentStreak']?.toInt() ?? 0,
      longestStreak: map['longestStreak']?.toInt() ?? 0,
      lastStreakDate: map['lastStreakDate'] ?? '',
      timeFormat: map['timeFormat'] ?? '12-hour',
      awards: List<String>.from(map['awards'] ?? []),
      celebratedAwards: List<String>.from(map['celebratedAwards'] ?? []),
      fcmToken: map['fcmToken'] ?? '',
      isPremium: map['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'activityLevel': activityLevel,
      'age': age,
      'bedTime': bedTime,
      'climate': climate,
      'gender': gender,
      'isKg': isKg,
      'isMl': isMl,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'wakeUpTime': wakeUpTime,
      'waterGoal': waterGoal,
      'weight': weight,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStreakDate': lastStreakDate,
      'timeFormat': timeFormat,
      'awards': awards,
      'celebratedAwards': celebratedAwards,
      'fcmToken': fcmToken,
      'isPremium': isPremium,
    };
  }
}
