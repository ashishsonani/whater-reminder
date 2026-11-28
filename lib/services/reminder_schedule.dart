import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

typedef ReminderSlot = ({
  int id,
  tz.TZDateTime date,
  DateTimeComponents? repeat,
  String key,
});

List<ReminderSlot> planReminderSlots(
  Map<int, Set<int>> weekdaysByMinute,
  tz.TZDateTime now, {
  required bool skipToday,
}) {
  final result = <ReminderSlot>[];
  for (final entry in weekdaysByMinute.entries) {
    final minute = entry.key;
    final weekdays = entry.value;
    tz.TZDateTime at(int offset) => tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + offset,
      minute ~/ 60,
      minute % 60,
    );
    final laterToday = at(0).isAfter(now);
    if (weekdays.length == 7 && (!skipToday || !laterToday)) {
      result.add((
        id: minute,
        date: at(laterToday ? 0 : 1),
        repeat: DateTimeComponents.time,
        key: 'daily',
      ));
      continue;
    }
    for (final weekday in weekdays) {
      var offset = (weekday - now.weekday + 7) % 7;
      final skipOccurrence = offset == 0 && laterToday && skipToday;
      if (offset == 0 && (!laterToday || skipOccurrence)) offset = 7;
      final date = at(offset);
      final repeat = skipOccurrence
          ? null
          : DateTimeComponents.dayOfWeekAndTime;
      result.add((
        id: weekday * 1440 + minute,
        date: date,
        repeat: repeat,
        key: repeat == null
            ? 'once-${date.millisecondsSinceEpoch}'
            : 'weekly-$weekday',
      ));
    }
  }
  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}
