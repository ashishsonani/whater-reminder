import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/models/water_record.dart';

class WaterLogDay {
  const WaterLogDay({this.goal = 0, this.isMl = true, this.records = const []});

  final int goal;
  final bool isMl;
  final List<WaterRecord> records;

  int total(bool inMl) => records.fold(0, (total, record) {
    if (record.isMl == inMl) return total + record.amount;
    return total +
        (inMl ? record.amount * 29.5735 : record.amount / 29.5735).round();
  });

  bool get goalMet => goal > 0 && total(isMl) >= goal;

  factory WaterLogDay.fromJson(Map<String, dynamic> json) => WaterLogDay(
    goal: json['goal'] as int,
    isMl: json['isMl'] as bool,
    records: (json['records'] as List)
        .cast<Map<String, dynamic>>()
        .map(WaterRecord.fromJson)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'goal': goal,
    'isMl': isMl,
    'records': records.map((record) => record.toJson()).toList(),
  };
}

class WaterLogStore {
  WaterLogStore._();
  static final instance = WaterLogStore._();
  static const _key = 'deviceWaterLogs';
  static const _importedKey = 'deviceWaterLogsImported';
  static String dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd', 'en_US').format(date.toLocal());

  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  Future<void> _pending = Future.value();

  Map<String, WaterLogDay> _read(SharedPreferences prefs) {
    final json =
        jsonDecode(prefs.getString(_key) ?? '{}') as Map<String, dynamic>;
    return json.map(
      (date, day) =>
          MapEntry(date, WaterLogDay.fromJson(day as Map<String, dynamic>)),
    );
  }

  Future<Map<String, WaterLogDay>> read() async =>
      _read(await SharedPreferences.getInstance());

  Future<void> _edit(
    void Function(Map<String, WaterLogDay>) edit, {
    bool importing = false,
    bool clear = false,
  }) {
    final result = _pending.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (importing && (prefs.getBool(_importedKey) ?? false)) return;
      final days = _read(prefs);
      edit(days);
      if (!await prefs.setString(_key, jsonEncode(days))) {
        throw StateError('Could not save water logs');
      }
      if (importing || clear) await prefs.setBool(_importedKey, true);
      _changes.add(null);
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<bool> needsImport() async =>
      !(await SharedPreferences.getInstance()).containsKey(_importedKey);

  Future<void> importHistory(Map<String, WaterLogDay> history) => _edit((days) {
    for (final entry in history.entries) {
      final local = days[entry.key];
      if (local == null) {
        days[entry.key] = entry.value;
        continue;
      }
      final records = {
        for (final record in entry.value.records) record.id: record,
      };
      for (final record in local.records) {
        records[record.id] = record;
      }
      days[entry.key] = WaterLogDay(
        goal: local.goal > 0 ? local.goal : entry.value.goal,
        isMl: local.goal > 0 ? local.isMl : entry.value.isMl,
        records: records.values.toList(),
      );
    }
  }, importing: true);

  Future<void> add(
    DateTime now,
    int amount,
    String type, {
    int? goal,
    bool? isMl,
    String? drinkType,
    String? recordId,
  }) => _edit((days) {
    final date = dateKey(now);
    final previousDates =
        days.keys.where((key) => key.compareTo(date) <= 0).toList()..sort();
    final day = days[date];
    final previous = previousDates.isEmpty ? null : days[previousDates.last];
    final unit = isMl ?? previous?.isMl ?? true;
    final target = goal ?? previous?.goal ?? 0;
    final records = day?.records ?? [];
    final id = recordId ?? now.microsecondsSinceEpoch.toString();
    if (records.any((record) => record.id == id)) return;
    final recordIsMl = isMl ?? true;
    final amountInGoalUnit = recordIsMl == unit
        ? amount
        : (unit ? amount * 29.5735 : amount / 29.5735).round();
    days[date] = WaterLogDay(
      goal: target,
      isMl: unit,
      records: [
        ...records,
        WaterRecord(
          id: id,
          amount: amount,
          type: type,
          createdAt: now,
          currentIntakeAtTime: (day?.total(unit) ?? 0) + amountInGoalUnit,
          targetIntakeAtTime: target,
          isMl: recordIsMl,
          drinkType: drinkType,
        ),
      ],
    );
  });

  Future<void> delete(WaterRecord record) =>
      deleteById(record.createdAt, record.id);

  Future<void> deleteById(DateTime dateTime, String id) => _edit((days) {
    final date = dateKey(dateTime);
    final day = days[date];
    if (day == null) return;
    days[date] = WaterLogDay(
      goal: day.goal,
      isMl: day.isMl,
      records: day.records.where((item) => item.id != id).toList(),
    );
  });

  Future<void> setGoal(int goal, bool isMl) => _edit((days) {
    final date = dateKey(DateTime.now());
    days[date] = WaterLogDay(
      goal: goal,
      isMl: isMl,
      records: days[date]?.records ?? [],
    );
  });

  Future<void> seedGoal(int goal, bool isMl) => _edit((days) {
    final date = dateKey(DateTime.now());
    if (days.values.any((day) => day.goal > 0)) return;
    final records = days[date]?.records ?? [];
    days[date] = WaterLogDay(goal: goal, isMl: isMl, records: records);
  });

  Future<void> clear() => _edit((days) => days.clear(), clear: true);
}
