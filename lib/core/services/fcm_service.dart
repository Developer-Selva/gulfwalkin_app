import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// The channel declared in AndroidManifest.xml must be created before FCM can
// deliver background notifications on Android 8+. If the channel doesn't exist,
// the OS silently discards incoming FCM pushes.
const _kChannelId   = 'gulfwalkin_alerts';
const _kChannelName = 'Gulfwalkin Job Alerts';
const _kChannelDesc = 'Notifications for new job postings matching your preferences';

// Must be top-level — runs in a separate isolate when app is terminated/background.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // System tray notification is shown automatically by FCM — nothing extra needed.
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  // Stores the notification that opened the app from a terminated state.
  // Consumed once by GulfwalkinApp on startup.
  static RemoteMessage? _pendingLaunchMessage;
  static RemoteMessage? consumeLaunchMessage() {
    final m = _pendingLaunchMessage;
    _pendingLaunchMessage = null;
    return m;
  }

  /// Call from main() — safe to call before runApp().
  /// Only registers the background handler; does NOT request permission.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  }

  /// Call AFTER the first frame is rendered (e.g. via addPostFrameCallback).
  /// Requesting permission in main() before the engine is running causes a
  /// crash on Android 13+ OEM devices (OnePlus/OPPO ColorOS) when the user
  /// grants the permission dialog — the process is suspended, then killed and
  /// restarted by the OEM process manager before Flutter finishes booting.
  static Future<void> init() async {
    // Android 8+ requires the notification channel to exist before FCM can
    // deliver background notifications. If the channel declared in
    // AndroidManifest.xml doesn't exist at the OS level, pushes are silently
    // dropped. Create it here, before requesting permission, so the channel
    // is ready the first time Firebase ever delivers a message.
    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _kChannelId,
              _kChannelName,
              description: _kChannelDesc,
              importance: Importance.high,
              playSound: true,
            ),
          );
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS foreground display options (no-op on Android).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Cache the launch message so GulfwalkinApp can navigate on startup.
    _pendingLaunchMessage = await _messaging.getInitialMessage();
  }

  /// Call after the user logs in (token is already saved to storage so Dio
  /// will attach the correct Authorization header automatically).
  static Future<void> registerToken(Dio dio) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await dio.post('/devices/register', data: {
        'token': token,
        'platform': 'android',
      });
    } catch (_) {}

    // Re-register whenever Firebase rotates the token.
    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        await dio.post('/devices/register', data: {
          'token': newToken,
          'platform': 'android',
        });
      } catch (_) {}
    });
  }

  /// Stream of messages received while the app is in the foreground.
  static Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  /// Stream fired when the user taps a notification while the app is backgrounded.
  static Stream<RemoteMessage> get onNotificationTap =>
      FirebaseMessaging.onMessageOpenedApp;
}
