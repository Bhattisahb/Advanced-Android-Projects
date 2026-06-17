import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grocery_app/services/in_app_notifications_hub.dart';
import 'package:grocery_app/services/system_local_notifications_service.dart';

/// Order alerts: Firestore listeners → **Notifications** tab ([InAppNotificationsHub]) +
/// **system tray** ([SystemLocalNotificationsService]; no FCM).
abstract final class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _adminOrdersSub;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _customerOrdersSub;
  static bool _adminOrdersInitialSync = true;
  static final Set<String> _adminSeenBatchKeys = {};
  static bool _customerOrdersInitialSync = true;
  static final Map<String, String> _customerFulfillmentByDocId = {};
  /// One aggregated alert per checkout batch (multi-line carts share [groupOrderId]).
  static final Set<String> _customerPlacedBatchKeys = {};

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await InAppNotificationsHub.instance.restore();
    _initialized = true;
  }

  static Future<void> _notifyInApp({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    await ensureInitialized();
    InAppNotificationsHub.instance.show(
      title: title,
      body: body,
      payload: payload,
    );
    await SystemLocalNotificationsService.showTray(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Called after splash gates confirm a verified session (customer or admin).
  static Future<void> syncSession({
    required User user,
    required bool isCustomerApp,
    required bool subscribeAdminTopic,
  }) async {
    await ensureInitialized();
    await SystemLocalNotificationsService.requestPostPermissionIfAndroid();

    final subscribeAdminAlerts = subscribeAdminTopic || !isCustomerApp;
    await _configureSparkOrderListeners(
      userId: user.uid,
      isCustomerApp: isCustomerApp,
      subscribeAdminAlerts: subscribeAdminAlerts,
    );
  }

  static Future<void> _configureSparkOrderListeners({
    required String userId,
    required bool isCustomerApp,
    required bool subscribeAdminAlerts,
  }) async {
    await stopSparkListeners();

    if (subscribeAdminAlerts) {
      _startAdminOrdersSparkListener();
    }
    if (isCustomerApp) {
      _startCustomerOrdersSparkListener(userId);
    }
  }

  static Future<void> stopSparkListeners() async {
    await _adminOrdersSub?.cancel();
    _adminOrdersSub = null;
    await _customerOrdersSub?.cancel();
    _customerOrdersSub = null;
    _adminOrdersInitialSync = true;
    _customerOrdersInitialSync = true;
    _adminSeenBatchKeys.clear();
    _customerFulfillmentByDocId.clear();
    _customerPlacedBatchKeys.clear();
  }

  static String _batchKeyFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final gid = data?['groupOrderId']?.toString().trim();
    if (gid != null && gid.isNotEmpty) return gid;
    return doc.id;
  }

  static void _startAdminOrdersSparkListener() {
    _adminOrdersSub?.cancel();
    _adminOrdersInitialSync = true;
    _adminSeenBatchKeys.clear();

    _adminOrdersSub = FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .listen(
      (snapshot) {
        if (_adminOrdersInitialSync) {
          _adminOrdersInitialSync = false;
          for (final d in snapshot.docs) {
            _adminSeenBatchKeys.add(_batchKeyFromDoc(d));
          }
          return;
        }
        final newBatchKeys = <String>[];
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final key = _batchKeyFromDoc(change.doc);
          if (_adminSeenBatchKeys.contains(key)) continue;
          _adminSeenBatchKeys.add(key);
          newBatchKeys.add(key);
        }
        if (newBatchKeys.isEmpty) return;
        if (_adminSeenBatchKeys.length > 500) {
          _adminSeenBatchKeys.clear();
        }
        final n = newBatchKeys.length;
        unawaited(
          _notifyInApp(
            title: 'New orders',
            body: n == 1
                ? '1 new order placed. Tap to open the list.'
                : '$n new orders placed. Tap to open the list.',
            payload: {
              'type': 'admin_new_orders',
              'count': '$n',
              InAppNotificationsHub.payloadTapAction:
                  InAppNotificationsHub.tapActionAdminOrders,
            },
          ),
        );
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('Admin orders listener error: $e');
        }
      },
    );
  }

  static void _startCustomerOrdersSparkListener(String uid) {
    _customerOrdersSub?.cancel();
    _customerOrdersInitialSync = true;
    _customerFulfillmentByDocId.clear();

    _customerOrdersSub = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (_customerOrdersInitialSync) {
          _customerOrdersInitialSync = false;
          for (final d in snapshot.docs) {
            final row = d.data();
            _customerFulfillmentByDocId[d.id] =
                (row['fulfillmentStatus'] ?? '').toString();
          }
          return;
        }
        var newPlacedBatches = 0;
        var statusChangeCount = 0;

        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final id = doc.id;
          final data = doc.data();
          final status = (data?['fulfillmentStatus'] ?? '').toString();

          switch (change.type) {
            case DocumentChangeType.added:
              _customerFulfillmentByDocId[id] = status;
              final batchKey = _batchKeyFromDoc(doc);
              if (!_customerPlacedBatchKeys.contains(batchKey)) {
                _customerPlacedBatchKeys.add(batchKey);
                if (_customerPlacedBatchKeys.length > 500) {
                  _customerPlacedBatchKeys.clear();
                }
                newPlacedBatches++;
              }
            case DocumentChangeType.modified:
              final prev = _customerFulfillmentByDocId[id] ?? '';
              _customerFulfillmentByDocId[id] = status;
              if (status.isNotEmpty && status != prev) {
                statusChangeCount++;
              }
            case DocumentChangeType.removed:
              _customerFulfillmentByDocId.remove(id);
          }
        }

        if (newPlacedBatches > 0 && statusChangeCount > 0) {
          unawaited(
            _notifyInApp(
              title: 'Orders',
              body: '${newPlacedBatches == 1 ? '1 new order' : '$newPlacedBatches new orders'}'
                  '${statusChangeCount == 1 ? ' and 1 status update' : ' and $statusChangeCount status updates'}'
                  '. Tap to view your orders.',
              payload: {
                'type': 'order_mixed',
                InAppNotificationsHub.payloadTapAction:
                    InAppNotificationsHub.tapActionCustomerOrders,
              },
            ),
          );
        } else if (newPlacedBatches > 0) {
          unawaited(
            _notifyInApp(
              title: 'Order placed',
              body: newPlacedBatches == 1
                  ? 'We received your order. Tap to view your orders.'
                  : 'We received $newPlacedBatches orders. Tap to view your orders.',
              payload: {
                'type': 'order_placed',
                InAppNotificationsHub.payloadTapAction:
                    InAppNotificationsHub.tapActionCustomerOrders,
              },
            ),
          );
        } else if (statusChangeCount > 0) {
          unawaited(
            _notifyInApp(
              title: 'Order updates',
              body: statusChangeCount == 1
                  ? 'Your order status changed. Tap to view your orders.'
                  : '$statusChangeCount orders had status updates. Tap to view your orders.',
              payload: {
                'type': 'order_status',
                InAppNotificationsHub.payloadTapAction:
                    InAppNotificationsHub.tapActionCustomerOrders,
              },
            ),
          );
        }
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('Customer orders listener error: $e');
        }
      },
    );
  }

  static Future<void> onSignedOut() async {
    await stopSparkListeners();
    await InAppNotificationsHub.instance.clear();
    await SystemLocalNotificationsService.cancelAll();
  }
}
