import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grocery_app/screens/admin/admin_orders_screen.dart';
import 'package:grocery_app/screens/orders/orders_screen.dart';
import 'package:grocery_app/services/in_app_notifications_hub.dart';

/// Android/iOS **system tray** notifications for order alerts (no FCM).
abstract final class SystemLocalNotificationsService {
  SystemLocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'orders_alerts',
    'Orders & alerts',
    description: 'New orders and order status updates',
    importance: Importance.high,
  );

  static bool _initialized = false;
  static int _nextId = 0;
  static String? _pendingLaunchPayload;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);

    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _pendingLaunchPayload =
            launch!.notificationResponse?.payload?.trim();
        if (_pendingLaunchPayload?.isEmpty ?? true) {
          _pendingLaunchPayload = null;
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('getNotificationAppLaunchDetails: $e\n$st');
      }
    }

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload?.trim();
    if (payload == null || payload.isEmpty) return;
    _scheduleNavigate(payload);
  }

  static void _scheduleNavigate(String payload) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateFromPayload(_navigatorKey?.currentState, payload);
    });
  }

  static void consumePendingLaunchNavigation() {
    final payload = _pendingLaunchPayload;
    if (payload == null || payload.isEmpty) return;
    _pendingLaunchPayload = null;
    _scheduleNavigate(payload);
  }

  static void _navigateFromPayload(NavigatorState? nav, String payload) {
    if (nav == null) return;
    if (payload == InAppNotificationsHub.tapActionCustomerOrders) {
      nav.pushNamed(OrdersScreen.routeName);
    } else if (payload == InAppNotificationsHub.tapActionAdminOrders) {
      nav.pushNamed(AdminOrdersScreen.routeName);
    }
  }

  /// Android 13+ runtime permission; safe to call repeatedly.
  static Future<void> requestPostPermissionIfAndroid() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<void> showTray({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    if (!_initialized) return;
    final tap =
        payload?[InAppNotificationsHub.payloadTapAction]?.toString().trim();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final id = (++_nextId & 0x7FFFFFFF);
    try {
      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: (tap != null && tap.isNotEmpty) ? tap : null,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Local notification show failed: $e\n$st');
      }
    }
  }

  static Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
