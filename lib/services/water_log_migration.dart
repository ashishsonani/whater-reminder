import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:water_intake/models/water_record.dart';
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/services/water_log_store.dart';

Future<void> importLegacyWaterLogs(String uid) async {
  final store = WaterLogStore.instance;
  if (!await store.needsImport()) return;
  final collection = FirebaseService().firestore
      .collection('users')
      .doc(uid)
      .collection('water_records');
  const source = GetOptions(source: Source.server);
  final summaries = await collection.get(source);
  final history = await Future.wait(
    summaries.docs.map((summary) async {
      final data = summary.data();
      final records = await summary.reference
          .collection('daily_records')
          .get(source);
      return MapEntry(
        summary.id,
        WaterLogDay(
          goal: (data['targetIntakeValue'] as num?)?.toInt() ?? 0,
          isMl: data['isMl'] as bool? ?? true,
          records: records.docs
              .map(
                (record) =>
                    WaterRecord.fromJson({...record.data(), 'id': record.id}),
              )
              .toList(),
        ),
      );
    }),
  );
  await store.importHistory(Map.fromEntries(history));
}
