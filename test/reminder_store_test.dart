import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/services/notification_service.dart';
import 'package:water_intake/services/reminder_store.dart';
import 'package:water_intake/view/account/screen/reminder/model/reminder_model.dart';

void main() {
  final store = ReminderStore.instance;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reminder edits and the master switch persist locally', () async {
    final defaultReminder = (await store.read()).single;
    await store.toggle(defaultReminder.id, false);
    await store.add('17:10');
    await store.setEnabled(false);

    final saved = await store.read();
    expect(saved.first.isEnabled, isFalse);
    expect(saved.last.time, '17:10');
    expect(await store.isEnabled(), isFalse);
    await store.delete(saved.last.id);
    expect(await store.read(), hasLength(1));
  });

  test(
    'import preserves a disabled default and drops expired cloud snoozes',
    () async {
      await store.importLegacy([
        Reminder(
          id: 'old-default',
          time: '8 AM – 10 PM',
          isEnabled: false,
          isCustom: false,
        ),
        Reminder(
          id: 'old-snooze',
          time: '1:20 PM',
          isEnabled: true,
          isSnooze: true,
        ),
      ], enabled: false);

      final saved = (await store.read()).single;
      expect(saved.id, 'old-default');
      expect(saved.isEnabled, isFalse);
      expect(await store.isEnabled(), isFalse);
      expect(await store.needsImport(), isFalse);
    },
  );

  test(
    'local schedules parse a 24-hour time and expand a repeating window',
    () {
      final service = NotificationService();
      expect(service.parseReminderTimes('17:10', null), [
        const TimeOfDay(hour: 17, minute: 10),
      ]);
      final times = service.parseReminderTimes('8 AM – 10 PM', 'Every 2 hours');
      expect(times.map((time) => time.hour), [8, 10, 12, 14, 16, 18, 20, 22]);
    },
  );
}
