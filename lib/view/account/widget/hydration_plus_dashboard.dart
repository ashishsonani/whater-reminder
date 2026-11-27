import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water_intake/models/hydration_plus_report.dart';
import 'package:water_intake/services/notification_service.dart';
import 'package:water_intake/services/reminder_store.dart';
import 'package:water_intake/services/water_log_store.dart';

class HydrationPlusDashboard extends StatefulWidget {
  const HydrationPlusDashboard({super.key});

  @override
  State<HydrationPlusDashboard> createState() => _HydrationPlusDashboardState();
}

class _HydrationPlusDashboardState extends State<HydrationPlusDashboard> {
  var _range = 30;
  var _saving = false;
  final _store = WaterLogStore.instance;
  late Future<Map<String, WaterLogDay>> _days;
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _days = _store.read();
    _changes = _store.changes.listen(
      (_) => setState(() => _days = _store.read()),
    );
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _addReminder(int hour) async {
    setState(() => _saving = true);
    var message = 'Reminder added'.tr;
    try {
      final store = ReminderStore.instance;
      final reminders = await store.read();
      final alreadyScheduled = reminders.any(
        (reminder) =>
            reminder.isEnabled == true &&
            NotificationService()
                .parseReminderTimes(reminder.time, reminder.interval)
                .contains(TimeOfDay(hour: hour, minute: 30)),
      );
      if (alreadyScheduled) {
        message = 'You already have a reminder at this time.'.tr;
      } else {
        await store.add('${hour.toString().padLeft(2, '0')}:30');
      }
    } catch (_) {
      message = 'Could not save the reminder. Try again.'.tr;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, WaterLogDay>>(
      future: _days,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Could not load hydration history.'.tr);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final report = HydrationPlusReport.fromDays(
          snapshot.data!,
          DateTime.now(),
          _range,
        );
        final suggestedHour = report.suggestedHour;
        final time = suggestedHour == null
            ? null
            : TimeOfDay(hour: suggestedHour, minute: 30).format(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydration trends'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 30, label: Text('30 days'.tr)),
                ButtonSegment(value: 90, label: Text('90 days'.tr)),
              ],
              selected: {_range},
              onSelectionChanged: (selection) =>
                  setState(() => _range = selection.single),
            ),
            const SizedBox(height: 12),
            if (report.trackedDays == 0)
              Text('Log some drinks to see your trends here.'.tr)
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Goals reached'.tr),
                trailing: Text('${report.goalDays} / $_range'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Weekday / weekend goals'.tr),
                trailing: Text(
                  '${report.weekdayGoalDays} / ${report.weekendGoalDays}',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Average on days you logged'.tr),
                trailing: Text('${report.averageMl} ml'),
              ),
            ],
            const Divider(),
            Text(
              'Reminder suggestion'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              time == null
                  ? 'Keep logging to see a suggestion based on days you missed your goal.'
                        .tr
                  : 'On days you missed your goal, you logged less often around @time. Try adding a reminder.'
                        .trParams({'time': time}),
            ),
            if (suggestedHour != null)
              TextButton.icon(
                onPressed: _saving ? null : () => _addReminder(suggestedHour),
                icon: const Icon(Icons.add_alarm),
                label: Text('Add @time reminder'.trParams({'time': time!})),
              ),
          ],
        );
      },
    );
  }
}
