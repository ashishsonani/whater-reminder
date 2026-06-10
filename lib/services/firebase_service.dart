import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/local_storage.dart';

class FirebaseService {
  FirebaseService._internal();
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  Future<String?> getUserId() async {
    // 1. Try to get UID from current authenticated user
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    }

    // 2. Try to get UID from LocalStorage
    return await LocalStorage.getUserId();
  }

  Future<void> updateFcmToken(String token) async {
    String? uid = await getUserId();
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateNotificationSettings(bool isEnabled) async {
    String? uid = await getUserId();
    if (uid != null) {
      await _firestore.collection('users').doc(uid).set({
        'isNotificationEnabled': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    String? uid = await getUserId();
    if (uid != null) {
      await _firestore.collection('users').doc(uid).set({
        'isPremium': isPremium,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
