import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/local_storage.dart';
import 'water_log_store.dart';

class FirebaseService {
  FirebaseService._internal();
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  Future<User>? _signIn;
  Future<void>? _profileImport;

  Future<User> authenticate() async {
    final user = _auth.currentUser;
    if (user != null) return user;
    try {
      return await (_signIn ??= _auth.signInAnonymously().then(
        (credential) => credential.user!,
      ));
    } finally {
      _signIn = null;
    }
  }

  Future<void> importLegacyProfile(String uid) async {
    if (LocalStorage.readHydrationProfile()['legacyImported'] == true) return;
    try {
      await (_profileImport ??= _importLegacyProfile(uid));
    } finally {
      _profileImport = null;
    }
  }

  Future<void> _importLegacyProfile(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    final data = doc.data() ?? {};
    final local = LocalStorage.readHydrationProfile();
    final imported = <String, dynamic>{};
    for (final key in [
      'gender',
      'weight',
      'isKg',
      'age',
      'wakeUpTime',
      'bedTime',
      'activityLevel',
      'climate',
      'timeFormat',
      'awards',
      'celebratedAwards',
    ]) {
      if (data[key] != null && !local.containsKey(key)) {
        imported[key] = data[key];
      }
    }
    final goal = (data['waterGoal'] as num?)?.toInt() ?? 0;
    if (goal > 0) {
      await WaterLogStore.instance.seedGoal(goal, data['isMl'] != false);
    }
    // Local changes made while the legacy profile was downloading take priority.
    final current = LocalStorage.readHydrationProfile();
    imported.removeWhere((key, value) => current.containsKey(key));
    await LocalStorage.updateHydrationProfile({
      ...imported,
      'legacyImported': true,
    });
  }
}
