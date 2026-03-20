import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'firebase_service.dart';

/// Top-level background handler — MUST be a top-level function
/// (not a class method) for Firebase Messaging to call it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // The system tray notification is shown automatically by FCM on Android.
  // No extra work needed here unless you want to store data locally.
}

/// Manages Firebase Cloud Messaging (push notifications).
///
/// Call [PushNotificationService.initialize] once at app startup
/// (after Firebase.initializeApp).  After the user logs in, call
/// [PushNotificationService.registerToken] to associate the device
/// token with the user on the backend.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  // ── Android notification channel ──
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'procurax_notifications', // id
    'ProcuraX Notifications', // name
    description: 'Notifications from ProcuraX app',
    importance: Importance.high,
    playSound: true,
  );

  /// One-time setup — call in main() after FirebaseService.initialize()
  static Future<void> initialize() async {
    if (!FirebaseService.isInitialized) {
      debugPrint('[FCM] Firebase not initialized — skipping FCM setup');
      return;
    }

    // 1. Request permission (Android 13+ and iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notifications permission denied');
      return;
    }

    // 2. Create the high-importance Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // 3. Initialize flutter_local_notifications (for foreground display)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 4. Get the FCM token
    //    On iOS, we must wait for the APNS token before requesting the FCM token.
    //    On the iOS simulator, APNS is unavailable so we skip gracefully.
    try {
      if (Platform.isIOS) {
        // Wait up to 10 seconds for the APNS token to become available
        String? apnsToken;
        for (int i = 0; i < 10; i++) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          debugPrint(
            '[FCM] APNS token not available (iOS simulator?) — skipping FCM token',
          );
          // Still set up listeners so the rest of the app works
          _setupListeners();
          return;
        }
      }
      _fcmToken = await _messaging.getToken();
      debugPrint('[FCM] Token: $_fcmToken');
    } catch (e) {
      debugPrint('[FCM] Could not get FCM token: $e');
      // Non-fatal — continue app startup without push token
    }

    _setupListeners();

    debugPrint('[FCM] Push notification service initialized ✅');
  }

  /// Sets up token refresh, foreground, background, and terminated-state listeners.
  static Future<void> _setupListeners() async {
    // Listen for token refreshes (e.g. app reinstall, token rotation)
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: $newToken');
      _fcmToken = newToken;
      // Re-register with backend if user is logged in
      if (ApiService.hasToken) {
        registerToken();
      }
    });

    // Handle foreground messages — show a local notification popup
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Handle notification taps when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check if app was opened from a terminated-state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }
  }

  // ── Show a heads-up notification when app is in the foreground ──
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('[FCM] Foreground message: ${notification.title}');

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'ProcuraX',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Called when user taps a notification (foreground local notif) ──
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Notification tapped, payload: ${response.payload}');
    // You can navigate to a specific page based on the payload data
    // e.g. navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
  }

  // ── Called when user taps a notification (from background/terminated) ──
  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] App opened from notification: ${message.data}');
    // Navigate to the relevant page based on message data
  }

  // ─────────────────────────────────────────────────────────────────
  // Token registration — call after login
  // ─────────────────────────────────────────────────────────────────

  /// Sends the current FCM token to the backend so it can send
  /// push notifications to this device.
  static Future<void> registerToken() async {
    if (_fcmToken == null || !ApiService.hasToken) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/fcm-token'),
        headers: ApiService.authHeaders,
        body: jsonEncode({'fcmToken': _fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] Token registered with backend ✅');
      } else {
        debugPrint(
          '[FCM] Failed to register token: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[FCM] Error registering token: $e');
    }
  }

  /// Remove the FCM token from the backend (call on logout)
  static Future<void> unregisterToken() async {
    if (!ApiService.hasToken) return;

    try {
      await http.delete(
        Uri.parse('${ApiService.baseUrl}/auth/fcm-token'),
        headers: ApiService.authHeaders,
      );
      debugPrint('[FCM] Token unregistered from backend');
    } catch (e) {
      debugPrint('[FCM] Error unregistering token: $e');
    }
  }
}
