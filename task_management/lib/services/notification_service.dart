import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream to broadcast payloads when a notification is tapped
  final StreamController<String?> _notificationStreamController = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationClick => _notificationStreamController.stream;

  NotificationService._internal();

  static const MethodChannel _androidChannel = MethodChannel('app.channel.notifications');

  /// Return true if notifications are enabled for this app (Android)
  Future<bool> areNotificationsEnabled() async {
    try {
      final res = await _androidChannel.invokeMethod<bool>('areNotificationsEnabled');
      return res == true;
    } catch (e) {
      return true; // assume enabled if check not available
    }
  }

  Future<void> openAppNotificationSettings() async {
    try {
      await _androidChannel.invokeMethod('openNotificationSettings');
    } catch (e) {
      // ignore
    }
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // deliver payload to listeners
        _notificationStreamController.add(response.payload);
      },
    );

    // If app was launched via a notification, read the payload and emit
    final details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      _notificationStreamController.add(details.notificationResponse?.payload);
    }

    tz.initializeTimeZones();

    // Ensure tz.local is set to the device local timezone. We use a platform
    // channel to query the native timezone to avoid adding a plugin that
    // may cause build issues on some environments.
    try {
      String? localTz;
      if (Platform.isAndroid || Platform.isIOS) {
        localTz = await _androidChannel.invokeMethod<String>('getLocalTimezone');
      }
      if (localTz != null && localTz.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(localTz));
      }
    } catch (e) {
      // fallback: tz.local will be whatever default is available
    }

    // Create Android notification channel so notifications show in the notification panel
    try {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      const channel = AndroidNotificationChannel(
        'task_channel', // id
        'Task Notifications', // name
        description: 'Notifications for task due dates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImpl?.createNotificationChannel(channel);
    } catch (e) {
      // ignore if platform implementation not available
    }
  }

  Future<void> scheduleTaskNotification(
    int id,
    String title,
    String description,
    DateTime scheduledDate,
  ) async {
    // Debug: print scheduling info
    try {
      // ignore: avoid_print
      print('Scheduling notification id=$id title="$title" at $scheduledDate (local tz=${tz.local.name})');
    } catch (_) {}

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      description,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task due dates',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Show an immediate notification (confirmation or simple alert)
  Future<void> showNotification(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task due dates',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Return currently pending (scheduled) notification requests.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      return <PendingNotificationRequest>[];
    }
  }
}