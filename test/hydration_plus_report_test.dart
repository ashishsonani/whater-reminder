import 'package:flutter_test/flutter_test.dart';
import 'package:water_intake/models/hydration_plus_report.dart';
import 'package:water_intake/models/water_record.dart';
import 'package:water_intake/services/water_log_store.dart';

void main() {
  WaterLogDay logged(
    DateTime date, {
    required int morning,
    int afternoon = 0,
  }) => WaterLogDay(
    goal: 500,
    records: [
      WaterRecord(
        id: 'a',
        amount: morning,
        type: 'Glass',
        createdAt: DateTime(date.year, date.month, date.day, 9),
      ),
      if (afternoon > 0)
        WaterRecord(
          id: 'b',
          amount: afternoon,
          type: 'Glass',
          createdAt: DateTime(date.year, date.month, date.day, 14),
        ),
    ],
  );

  test(
    'uses finished days, reports weekday and weekend goals, and suggests a quieter period',
    () {
      final now = DateTime(2026, 11, 27);
      final days = {
        '2026-11-27': logged(now, morning: 500),
        '2026-11-26': logged(DateTime(2026, 11, 26), morning: 500),
        '2026-11-25': logged(
          DateTime(2026, 11, 25),
          morning: 100,
          afternoon: 100,
        ),
        '2026-11-24': logged(
          DateTime(2026, 11, 24),
          morning: 100,
          afternoon: 100,
        ),
        '2026-11-23': logged(
          DateTime(2026, 11, 23),
          morning: 100,
          afternoon: 100,
        ),
        '2026-11-22': logged(DateTime(2026, 11, 22), morning: 500),
      };

      final report = HydrationPlusReport.fromDays(days, now, 30);
      expect(report.trackedDays, 5);
      expect(report.goalDays, 2);
      expect(report.weekdayGoalDays, 1);
      expect(report.weekendGoalDays, 1);
      expect(report.weekdayDays + report.weekendDays, 30);
      expect(report.averageMl, 320);
      expect(report.suggestedHour, 19);
    },
  );

  test('a sparse history does not produce a reminder suggestion', () {
    final now = DateTime(2026, 11, 27);
    final report = HydrationPlusReport.fromDays(
      {
        '2026-11-26': logged(
          DateTime(2026, 11, 26),
          morning: 100,
          afternoon: 100,
        ),
      },
      now,
      90,
    );
    expect(report.suggestedHour, isNull);
    expect(report.goalDays, 0);
  });
}
