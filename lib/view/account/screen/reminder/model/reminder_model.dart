// To parse this JSON data, do
//
//     final reminderList = reminderListFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

ReminderList reminderListFromJson(String str) => ReminderList.fromJson(json.decode(str));

String reminderListToJson(ReminderList data) => json.encode(data.toJson());

class ReminderList {
  String? message;
  Data? data;

  ReminderList({this.message, this.data});

  ReminderList copyWith({String? message, Data? data}) => ReminderList(message: message ?? this.message, data: data ?? this.data);

  factory ReminderList.fromJson(Map<String, dynamic> json) =>
      ReminderList(message: json["message"], data: json["data"] == null ? null : Data.fromJson(json["data"]));

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  bool? remindersEnabled;
  List<Reminder>? reminders;

  Data({this.remindersEnabled, this.reminders});

  Data copyWith({bool? remindersEnabled, List<Reminder>? reminders}) =>
      Data(remindersEnabled: remindersEnabled ?? this.remindersEnabled, reminders: reminders ?? this.reminders);

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    remindersEnabled: json["remindersEnabled"],
    reminders: json["reminders"] == null ? [] : List<Reminder>.from(json["reminders"]!.map((x) => Reminder.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "remindersEnabled": remindersEnabled,
    "reminders": reminders == null ? [] : List<dynamic>.from(reminders!.map((x) => x.toJson())),
  };
}

class Reminder {
  String? id;
  String? time;
  String? interval;
  bool? isEnabled;
  bool? isCustom;
  bool? isSnooze;
  DateTime? createdAt;

  Reminder({this.id, this.time, this.interval, this.isEnabled, this.isCustom, this.isSnooze, this.createdAt});

  Reminder copyWith({String? id, String? time, String? interval, bool? isEnabled, bool? isCustom, bool? isSnooze, DateTime? createdAt}) => Reminder(
    id: id ?? this.id,
    time: time ?? this.time,
    interval: interval ?? this.interval,
    isEnabled: isEnabled ?? this.isEnabled,
    isCustom: isCustom ?? this.isCustom,
    isSnooze: isSnooze ?? this.isSnooze,
    createdAt: createdAt ?? this.createdAt,
  );

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json["id"],
    time: json["timeRange"],
    interval: json["interval"],
    isEnabled: json["isActive"] ?? json["isEnabled"], // Support both Firestore and local keys
    isCustom: json["isCustom"],
    isSnooze: json["isSnooze"],
    createdAt: json["createdAt"] != null ? (json["createdAt"] as Timestamp).toDate() : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "timeRange": time,
    "interval": interval,
    "isActive": isEnabled,
    "isCustom": isCustom,
    "isSnooze": isSnooze,
    "createdAt": createdAt != null ? Timestamp.fromDate(createdAt!) : null,
  };
}
