import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/models/water_record.dart';
import 'package:water_intake/services/water_log_store.dart';

void main() {
  final store = WaterLogStore.instance;
  final now = DateTime(2026, 1, 2, 12);
  final date = WaterLogStore.dateKey(now);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'concurrent logs persist and deleting one recalculates the total',
    () async {
      await Future.wait([
        store.add(now, 200, 'Glass', goal: 450, isMl: true),
        store.add(now.add(const Duration(seconds: 1)), 250, 'Glass'),
      ]);

      final day = (await store.read())[date]!;
      expect(day.records.map((entry) => entry.amount), [200, 250]);
      expect(day.total(true), 450);
      expect(day.goalMet, isTrue);

      await store.delete(day.records.first);
      final updated = (await store.read())[date]!;
      expect(updated.total(true), 250);
      expect(updated.goalMet, isFalse);
    },
  );

  test(
    'notification logging retains 250 ml when the goal uses ounces',
    () async {
      await store.add(now, 1, 'Cup', goal: 9, isMl: false);
      await store.add(now.add(const Duration(seconds: 1)), 250, 'Glass');

      final day = (await store.read())[date]!;
      expect(day.records.last.amount, 250);
      expect(day.records.last.isMl, isTrue);
      expect(day.total(false), 9);
      expect(day.total(true), 280);
      expect(day.goalMet, isTrue);
    },
  );

  test(
    'legacy import merges existing device entries and does not run again after reset',
    () async {
      final legacy = {
        date: WaterLogDay(
          goal: 500,
          records: [
            WaterRecord(id: 'legacy', amount: 100, type: 'Cup', createdAt: now),
          ],
        ),
      };
      await store.add(now, 250, 'Glass');
      await store.importHistory(legacy);
      await store.importHistory(legacy);

      final day = (await store.read())[date]!;
      expect(day.records, hasLength(2));
      expect(day.total(true), 350);
      expect(day.goal, 500);

      await store.clear();
      await store.importHistory(legacy);
      expect(await store.read(), isEmpty);
    },
  );
}
