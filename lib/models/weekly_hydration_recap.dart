import 'package:water_intake/services/water_log_store.dart';

enum LoggingPeriod { morning, afternoon, evening, overnight }

class WeeklyHydrationRecap {
  const WeeklyHydrationRecap({
    required this.goalDays,
    required this.loggedDays,
    required this.mostConsistentPeriod,
    required this.periodDays,
  });

  static const dayCount = 7;
  static const empty = WeeklyHydrationRecap(
    goalDays: 0,
    loggedDays: 0,
    mostConsistentPeriod: null,
    periodDays: 0,
  );

  final int goalDays;
  final int loggedDays;
  final LoggingPeriod? mostConsistentPeriod;
  final int periodDays;

  factory WeeklyHydrationRecap.fromDays(
    Map<String, WaterLogDay> days,
    DateTime today,
  ) {
    var goalDays = 0;
    var loggedDays = 0;
    final counts = {for (final period in LoggingPeriod.values) period: 0};
    for (var offset = 0; offset < dayCount; offset++) {
      final date = DateTime(today.year, today.month, today.day - offset);
      final day = days[WaterLogStore.dateKey(date)];
      if (day == null) continue;
      if (day.goalMet) goalDays++;
      if (day.records.isEmpty) continue;
      loggedDays++;
      final periods = day.records
          .map(
            (record) => switch (record.createdAt.toLocal().hour) {
              >= 5 && < 12 => LoggingPeriod.morning,
              >= 12 && < 17 => LoggingPeriod.afternoon,
              >= 17 && < 23 => LoggingPeriod.evening,
              _ => LoggingPeriod.overnight,
            },
          )
          .toSet();
      for (final period in periods) {
        counts[period] = counts[period]! + 1;
      }
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final leader = ranked.first;
    return WeeklyHydrationRecap(
      goalDays: goalDays,
      loggedDays: loggedDays,
      mostConsistentPeriod: leader.value >= 2 && leader.value > ranked[1].value
          ? leader.key
          : null,
      periodDays: leader.value,
    );
  }
}
