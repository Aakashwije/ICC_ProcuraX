import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/meeting.dart';
import 'meeting_location_service.dart';

/// Service for scheduling smart meeting notifications:
///
/// 1. **Standard reminder**: 1 hour before the meeting start time.
/// 2. **Smart travel alert**: If the user is far enough that travel time
///    exceeds 1 hour, the notification fires earlier so they have time
///    to leave (travelTime + 15 min buffer before meeting).
///
/// Each meeting gets two notification IDs:
/// - Standard:  hash based on meeting ID + "reminder"
/// - Travel:    hash based on meeting ID + "travel"
class MeetingNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Android channel ─────────────────────────────────────────────────────

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'meeting_reminders',
    'Meeting Reminders',
    description: 'Smart location-aware reminders for upcoming meetings',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // ── Initialize ──────────────────────────────────────────────────────────

  /// Call once at app startup (e.g. in main.dart).
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // Initialize the plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    _initialized = true;
    debugPrint('[MeetingNotifications] Initialized ✅');
  }

  // ── Schedule notifications for a meeting ────────────────────────────────

  /// Schedules smart notifications for the given [meeting].
  /// - Always schedules a **1-hour reminder**.
  /// - If the meeting has coordinates, checks user distance and may
  ///   schedule an **earlier travel alert**.
  static Future<void> scheduleMeetingNotifications(Meeting meeting) async {
    if (!_initialized) await initialize();

    final meetingId = meeting.id ?? meeting.title.hashCode.toString();

    // Cancel any existing notifications for this meeting
    await cancelMeetingNotifications(meetingId);

    final now = DateTime.now();
    final startTime = meeting.startTime;

    // Don't schedule for past meetings
    if (startTime.isBefore(now)) return;

    // ── 1. Standard 1-hour reminder ──────────────────────────────────────
    final reminderTime = startTime.subtract(const Duration(hours: 1));
    if (reminderTime.isAfter(now)) {
      await _scheduleNotification(
        id: _reminderId(meetingId),
        title: '📅 Meeting in 1 hour',
        body:
            '${meeting.title}'
            '${meeting.location.isNotEmpty ? ' at ${meeting.location}' : ''}',
        scheduledTime: reminderTime,
      );
      debugPrint(
        '[MeetingNotifications] Scheduled 1hr reminder for "${meeting.title}" '
        'at ${reminderTime.toIso8601String()}',
      );
    }

    // ── 2. Smart travel alert (if coordinates available) ─────────────────
    if (meeting.hasCoordinates) {
      try {
        final distanceInfo = await MeetingLocationService.getDistanceToLocation(
          meetingLat: meeting.latitude!,
          meetingLng: meeting.longitude!,
        );

        if (distanceInfo != null) {
          final travelMinutes = distanceInfo.travelTimeMinutes;
          final distanceKm = distanceInfo.distanceKm;

          debugPrint(
            '[MeetingNotifications] Distance to "${meeting.title}": '
            '${distanceInfo.formattedDistance}, '
            'est. travel: ${distanceInfo.formattedTravelTime}',
          );

          // If travel time > 60 min, user can't reach in 1hr → send early alert
          if (travelMinutes > 60) {
            // Alert = travelTime + 15 min buffer before meeting
            final bufferMinutes = travelMinutes + 15;
            final travelAlertTime = startTime.subtract(
              Duration(minutes: bufferMinutes),
            );

            if (travelAlertTime.isAfter(now)) {
              await _scheduleNotification(
                id: _travelId(meetingId),
                title: '🚗 Leave now for your meeting!',
                body:
                    '${meeting.title} is ${MeetingLocationService.formatDistance(distanceKm)} away '
                    '(${MeetingLocationService.formatTravelTime(travelMinutes)}). '
                    'Leave now to arrive on time.',
                scheduledTime: travelAlertTime,
              );
              debugPrint(
                '[MeetingNotifications] Scheduled travel alert at '
                '${travelAlertTime.toIso8601String()}',
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[MeetingNotifications] Error getting distance: $e');
      }
    }
  }

  // ── Cancel notifications for a meeting ──────────────────────────────────

  /// Cancels all notifications associated with the given [meetingId].
  static Future<void> cancelMeetingNotifications(String meetingId) async {
    await _notifications.cancel(_reminderId(meetingId));
    await _notifications.cancel(_travelId(meetingId));
    debugPrint(
      '[MeetingNotifications] Cancelled notifications for meeting $meetingId',
    );
  }

  // ── Reschedule all notifications ────────────────────────────────────────

  /// Reschedules notifications for a list of upcoming meetings.
  /// Call this on app startup to refresh notification schedules.
  static Future<void> rescheduleAll(List<Meeting> meetings) async {
    if (!_initialized) await initialize();

    // Cancel all existing meeting reminders first
    await _notifications.cancelAll();

    final now = DateTime.now();
    for (final meeting in meetings) {
      if (meeting.startTime.isAfter(now) && !meeting.isDone) {
        await scheduleMeetingNotifications(meeting);
      }
    }

    debugPrint(
      '[MeetingNotifications] Rescheduled notifications for '
      '${meetings.where((m) => m.startTime.isAfter(now) && !m.isDone).length} meetings',
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  static int _reminderId(String meetingId) =>
      '${meetingId}_reminder'.hashCode.abs() % 2147483647;

  static int _travelId(String meetingId) =>
      '${meetingId}_travel'.hashCode.abs() % 2147483647;

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          // Custom white vector icon — clean in status bar
          icon: '@drawable/ic_notification_bell',
          // ProcuraX brand blue accent
          color: const Color(0xFF1565C0),
          // Expand full body text in the notification shade
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: false,
            contentTitle: title,
            htmlFormatContentTitle: false,
            summaryText: 'ProcuraX · Meeting Reminder',
          ),
          subText: 'ProcuraX',
          playSound: true,
          enableVibration: true,
          showWhen: true,
          when: scheduledTime.millisecondsSinceEpoch,
          // Keep reminder visible until dismissed
          ongoing: false,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }
}
