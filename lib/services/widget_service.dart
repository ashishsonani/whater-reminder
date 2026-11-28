import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/services/water_log_store.dart';

/// Transfers native widget taps to the device log and publishes one progress
/// snapshot. Native widgets overlay pending taps until the app acknowledges them.
class WidgetService with WidgetsBindingObserver {
  WidgetService._();
  static final _instance = WidgetService._();
  static const appGroupId = 'group.com.sarang.waterreminder';
  static const _ackKey = 'widgetQuickLogAcknowledged';
  static Future<void> _pending = Future.value();
  static bool _initialized = false;
  static bool _queued = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      WidgetsBinding.instance.addObserver(_instance);
      WaterLogStore.instance.changes.listen((_) => sync());
      await sync();
    } catch (error) {
      debugPrint('Widget initialization failed: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(sync());
  }

  static Future<void> sync() {
    if (!_initialized || _queued) return _pending;
    _queued = true;
    _pending = _pending
        .then((_) async {
          _queued = false;
          final prefs = await SharedPreferences.getInstance();
          final savedAck = prefs.getInt(_ackKey) ?? 0;
          var ack = savedAck;
          final payload = await HomeWidget.getWidgetData<String>(
            'quick_log_queue',
          );
          final queue =
              (jsonDecode(payload ?? '[]') as List).cast<Map<String, dynamic>>()
                ..sort((a, b) => (a['at'] as int).compareTo(b['at'] as int));
          final canceled = queue
              .map((event) => event['undo'])
              .whereType<int>()
              .toSet();
          final store = WaterLogStore.instance;
          for (final event in queue) {
            final timestamp = event['at'] as int;
            if (timestamp <= ack) continue;
            final undo = event['undo'] as int?;
            if (undo == null) {
              final now = DateTime.fromMicrosecondsSinceEpoch(timestamp);
              if (!canceled.contains(timestamp)) {
                await store.add(
                  now,
                  250,
                  'Glass',
                  recordId: 'widget-$timestamp',
                );
              }
            } else {
              await store.deleteById(
                DateTime.fromMicrosecondsSinceEpoch(undo),
                'widget-$undo',
              );
            }
            ack = timestamp;
          }
          if (ack != savedAck && !await prefs.setInt(_ackKey, ack)) {
            throw StateError('Could not acknowledge widget logs');
          }
          final now = DateTime.now();
          final days = await store.read();
          final todayKey = WaterLogStore.dateKey(now);
          final today = days[todayKey];
          final dates =
              days.keys
                  .where(
                    (key) =>
                        key.compareTo(todayKey) <= 0 && days[key]!.goal > 0,
                  )
                  .toList()
                ..sort();
          final settings = dates.isEmpty
              ? const WaterLogDay()
              : days[dates.last]!;
          final current = today?.total(settings.isMl) ?? 0;
          await HomeWidget.saveWidgetData<String>(
            'quick_log_snapshot',
            jsonEncode({
              'current': current,
              'goal': settings.goal,
              'isMl': settings.isMl,
              'dayStart': DateTime(
                now.year,
                now.month,
                now.day,
              ).millisecondsSinceEpoch,
              'ack': ack,
              'ready': prefs.getBool('isSetupComplete') ?? false,
            }),
          );
          await HomeWidget.updateWidget(
            iOSName: 'WaterWidget',
            androidName: 'WaterWidgetProvider',
          );
        })
        .catchError((Object error) {
          debugPrint('Widget sync failed: $error');
        });
    return _pending;
  }
}
