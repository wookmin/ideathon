import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  const LocalNotificationService._();

  static const _androidSmallIcon = 'notification_icon';
  static const _androidLargeIcon = 'app_notification_large';
  static const _channelId = 'budget_alerts';
  static const _channelName = 'Budget alerts';
  static const _channelDescription = 'Travel budget and location alerts';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings(_androidSmallIcon);
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static Future<void> show({
    required String title,
    required String message,
    int? id,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;

    final notificationId =
        id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      icon: _androidSmallIcon,
      largeIcon: DrawableResourceAndroidBitmap(_androidLargeIcon),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.recommendation,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(
        id: notificationId,
        title: title,
        body: message,
        notificationDetails: details,
      );
    } catch (_) {}
  }
}
