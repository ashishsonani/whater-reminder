import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/view/account/screen/reminder/model/reminder_model.dart';

class ReminderStore {
  ReminderStore._();
  static final instance = ReminderStore._();
  static const _key = 'deviceReminders';
  static const _imported = 'deviceRemindersImported';
  static const _enabledKey = 'notifications_enabled';

  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  Future<void> _pending = Future.value();

  List<Reminder> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) {
      return [
        Reminder(
          id: 'default',
          time: '8 AM – 10 PM',
          interval: 'Every 2 hours',
          isEnabled: true,
          isCustom: false,
        ),
      ];
    }
    final entries = jsonDecode(raw) as List;
    return entries.cast<Map<String, dynamic>>().map(Reminder.fromJson).toList();
  }

  Future<List<Reminder>> read() async =>
      _read(await SharedPreferences.getInstance());
  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? true;
  Future<bool> needsImport() async =>
      !(await SharedPreferences.getInstance()).containsKey(_imported);

  Future<void> _edit(Future<void> Function(SharedPreferences) edit) {
    final result = _pending.then((_) async {
      await edit(await SharedPreferences.getInstance());
      _changes.add(null);
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _save(SharedPreferences prefs, List<Reminder> reminders) async {
    if (!await prefs.setString(_key, jsonEncode(reminders))) {
      throw StateError('Could not save reminders');
    }
  }

  Future<void> setEnabled(bool enabled) => _edit((prefs) async {
    if (!await prefs.setBool(_enabledKey, enabled)) {
      throw StateError('Could not save reminder setting');
    }
  });

  Future<void> add(String time) => _edit((prefs) async {
    final now = DateTime.now();
    await _save(prefs, [
      ..._read(prefs),
      Reminder(
        id: now.microsecondsSinceEpoch.toString(),
        time: time,
        isEnabled: true,
        isCustom: true,
        createdAt: now,
      ),
    ]);
  });

  Future<void> toggle(String? id, bool enabled) => _edit((prefs) async {
    await _save(prefs, [
      for (final reminder in _read(prefs))
        if (reminder.id == id)
          reminder.copyWith(isEnabled: enabled)
        else
          reminder,
    ]);
  });

  Future<void> delete(String? id) => _edit((prefs) async {
    await _save(
      prefs,
      _read(prefs)..removeWhere((reminder) => reminder.id == id),
    );
  });

  Future<void> importLegacy(
    List<Reminder> reminders, {
    required bool enabled,
  }) => _edit((prefs) async {
    if (prefs.containsKey(_imported)) return;
    final saved = _read(prefs);
    final alreadyEdited = prefs.containsKey(_key);
    final imported = reminders.where((reminder) => reminder.isSnooze != true);
    final hasLegacyDefault = imported.any(
      (reminder) => reminder.isCustom != true,
    );
    final local = alreadyEdited || !hasLegacyDefault
        ? saved
        : saved.where((reminder) => reminder.isCustom == true).toList();

    await _save(prefs, [
      ...local,
      ...imported.where(
        (reminder) =>
            !alreadyEdited ||
            (reminder.isCustom == true &&
                !local.any((saved) => saved.time == reminder.time)),
      ),
    ]);
    if (!prefs.containsKey(_enabledKey)) {
      await prefs.setBool(_enabledKey, enabled);
    }
    await prefs.setBool(_imported, true);
  });
}
