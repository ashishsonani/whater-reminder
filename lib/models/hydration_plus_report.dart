import 'package:water_intake/services/water_log_store.dart';

class HydrationPlusReport {
  const HydrationPlusReport({
    required this.goalDays,
    required this.trackedDays,
    required this.weekdayGoalDays,
    required this.weekendGoalDays,
    required this.weekdayDays,
    required this.weekendDays,
    required this.averageMl,
    required this.suggestedHour,
  });

  final int goalDays;
  final int trackedDays;
  final int weekdayGoalDays;
  final int weekendGoalDays;
  final int weekdayDays;
  final int weekendDays;
  final int averageMl;
  final int? suggestedHour;

  factory HydrationPlusReport.fromDays(
    Map<String, WaterLogDay> days,
    DateTime today,
    int range,
  ) {
    var trackedDays = 0;
    var weekdayGoalDays = 0;
    var weekendGoalDays = 0;
    var weekdayDays = 0;
    var weekendDays = 0;
    var totalMl = 0;
    var missedWithLogs = 0;
    final missedDayLogging = {9: 0, 14: 0, 19: 0};

    for (var offset = 1; offset <= range; offset++) {
      final date = DateTime(today.year, today.month, today.day - offset);
      if (date.weekday <= DateTime.friday) {
        weekdayDays++;
      } else {
        weekendDays++;
      }
      final day = days[WaterLogStore.dateKey(date)];
      if (day == null || day.records.isEmpty) continue;
      trackedDays++;
      totalMl += day.total(true);
      if (day.goalMet) {
        if (date.weekday <= DateTime.friday) {
          weekdayGoalDays++;
        } else {
          weekendGoalDays++;
        }
      } else if (day.goal > 0 && offset <= 30) {
        missedWithLogs++;
        final hours = day.records.map(
          (record) => record.createdAt.toLocal().hour,
        );
        if (hours.any((hour) => hour >= 5 && hour < 12)) {
          missedDayLogging[9] = missedDayLogging[9]! + 1;
        }
        if (hours.any((hour) => hour >= 12 && hour < 17)) {
          missedDayLogging[14] = missedDayLogging[14]! + 1;
        }
        if (hours.any((hour) => hour >= 17 && hour < 23)) {
          missedDayLogging[19] = missedDayLogging[19]! + 1;
        }
      }
    }

    final ranked = missedDayLogging.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final suggestion =
        missedWithLogs >= 3 && ranked.first.value < ranked[1].value
        ? ranked.first.key
        : null;
    return HydrationPlusReport(
      goalDays: weekdayGoalDays + weekendGoalDays,
      trackedDays: trackedDays,
      weekdayGoalDays: weekdayGoalDays,
      weekendGoalDays: weekendGoalDays,
      weekdayDays: weekdayDays,
      weekendDays: weekendDays,
      averageMl: trackedDays > 0 ? (totalMl / trackedDays).round() : 0,
      suggestedHour: suggestion,
    );
  }
}
