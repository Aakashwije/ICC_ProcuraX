import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
      debugPrint('⚠️ Firebase features will be disabled');
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;

  static Future<void> saveUserData(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Firebase not initialized, skipping saveUserData');
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
  }

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Firebase not initialized, skipping getUserData');
      return null;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data();
  }

  static Future<void> syncUserOnLogin(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Firebase not initialized, skipping syncUserOnLogin');
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        ...userData,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firebase Sync Error: $e');
    }
  }
}
