import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import 'package:water_intake/models/water_record.dart';
import 'package:water_intake/models/weekly_hydration_recap.dart';
import 'package:water_intake/services/reminder_schedule.dart';
import 'package:water_intake/services/reminder_store.dart';
import 'package:water_intake/services/water_log_store.dart';
import 'package:water_intake/theme/rewarded_theme.dart';
import 'package:water_intake/view/account/screen/reminder/model/reminder_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'the weekend schedule skips Saturday only when reminders are paused',
    () {
      zones.initializeTimeZones();
      final location = tz.getLocation('America/New_York');
      final saturday = tz.TZDateTime(location, 2026, 3, 7, 9);
      final preferences = {10 * 60: ReminderDays.weekends.days};

      final paused = planReminderSlots(preferences, saturday, skipToday: true);
      expect(paused.first.date.weekday, DateTime.sunday);
      expect(paused.first.date.hour, 10);
      expect(paused.first.repeat, DateTimeComponents.dayOfWeekAndTime);
      expect(paused.last.date.day, 14);
      expect(paused.last.repeat, isNull);

      final resumed = planReminderSlots(
        preferences,
        saturday,
        skipToday: false,
      );
      expect(resumed.first.date.day, 7);
      expect(resumed.first.repeat, DateTimeComponents.dayOfWeekAndTime);
    },
  );

  test(
    'all-week schedules retain a daily repeat after today’s time has passed',
    () {
      final now = tz.TZDateTime(tz.UTC, 2026, 3, 7, 11);
      final slots = planReminderSlots(
        {600: ReminderDays.everyDay.days},
        now,
        skipToday: true,
      );
      expect(slots.single.date.day, 8);
      expect(slots.single.repeat, DateTimeComponents.time);
    },
  );

  test(
    'reminder schedules and preferences persist and a pause expires tomorrow',
    () async {
      final store = ReminderStore.instance;
      final item = (await store.read()).single;
      final now = DateTime.now();
      await store.setDays(item.id, ReminderDays.weekdays);
      await store.setStopsAtGoal(false);
      await store.setPausedToday(true);

      expect((await store.read()).single.days, ReminderDays.weekdays);
      expect(await store.stopsAtGoal(), isFalse);
      expect(await store.isPausedOn(now), isTrue);
      expect(
        await store.isPausedOn(DateTime(now.year, now.month, now.day + 1)),
        isFalse,
      );
    },
  );

  test('weekly recap counts distinct days rather than individual taps', () {
    WaterRecord drink(String id, int day, int hour, int amount) => WaterRecord(
      id: id,
      createdAt: DateTime(2026, 11, day, hour),
      amount: amount,
      type: 'Glass',
    );
    final recap = WeeklyHydrationRecap.fromDays({
      '2026-11-26': WaterLogDay(
        goal: 500,
        records: [drink('a', 26, 9, 250), drink('b', 26, 10, 250)],
      ),
      '2026-11-25': WaterLogDay(
        goal: 500,
        records: [drink('c', 25, 8, 200), drink('d', 25, 19, 100)],
      ),
      '2026-11-19': WaterLogDay(goal: 200, records: [drink('e', 19, 20, 300)]),
    }, DateTime(2026, 11, 26));

    expect(recap.goalDays, 1);
    expect(recap.loggedDays, 2);
    expect(recap.mostConsistentPeriod, LoggingPeriod.morning);
    expect(recap.periodDays, 2);
  });

  test('a widget log is idempotent and Undo removes only that entry', () async {
    final store = WaterLogStore.instance;
    final now = DateTime(2026, 11, 26, 9);
    await store.add(now, 200, 'Cup', recordId: 'home');
    await store.add(now, 250, 'Glass', recordId: 'widget');
    await store.add(now, 250, 'Glass', recordId: 'widget');

    expect((await store.read())[WaterLogStore.dateKey(now)]!.total(true), 450);
    await store.deleteById(now, 'widget');
    final day = (await store.read())[WaterLogStore.dateKey(now)]!;
    expect(day.records.single.id, 'home');
    expect(day.total(true), 200);
  });

  test(
    'Forest Spring unlocks at seven days and stays earned after a restart',
    () async {
      final theme = MilestoneTheme();
      final restored = MilestoneTheme();
      addTearDown(theme.dispose);
      addTearDown(restored.dispose);

      await theme.recordStreak(6);
      await theme.select(true);
      expect(theme.selected, isFalse);
      await theme.recordStreak(7);
      await theme.select(true);
      await restored.restore();

      expect(restored.unlocked, isTrue);
      expect(restored.selected, isTrue);
    },
  );
}
