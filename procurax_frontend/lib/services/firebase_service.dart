import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  static Future<void> saveUserData(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
  }

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> syncUserOnLogin(String uid, Map<String, dynamic> userData) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          ...userData,
          'lastLogin': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Firebase Sync Error: $e');
    }
  }
}
