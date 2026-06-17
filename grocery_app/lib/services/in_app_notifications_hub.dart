import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Order / messaging alerts persisted for the **Notifications** tab (no overlay banners).
/// Matching alerts can still appear in the device tray from local notifications.
/// Persisted locally so they survive restarts while offline.
class InAppNotificationEntry {
  InAppNotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.payload = const {},
  });

  final String id;
  final String title;
  final String body;
  final DateTime at;
  final Map<String, String> payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'at': at.toIso8601String(),
        'payload': payload,
      };

  factory InAppNotificationEntry.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final payload = <String, String>{};
    if (rawPayload is Map) {
      rawPayload.forEach((k, v) {
        payload['$k'] = '$v';
      });
    }
    return InAppNotificationEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
      payload: payload,
    );
  }
}

/// Singleton hub for in-app toasts + persisted history ([entries]).
class InAppNotificationsHub extends ChangeNotifier {
  InAppNotificationsHub._();

  static final InAppNotificationsHub instance = InAppNotificationsHub._();

  static const _prefsKey = 'in_app_notifications_v1';
  static const _maxStored = 50;

  /// [InAppNotificationEntry.payload] keys for overlay / list tap navigation.
  static const payloadTapAction = 'tapAction';
  static const tapActionCustomerOrders = 'customer_orders';
  static const tapActionAdminOrders = 'admin_orders';

  final List<InAppNotificationEntry> _entries = [];

  List<InAppNotificationEntry> get entries => List.unmodifiable(_entries);

  bool _restored = false;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _entries
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((e) => InAppNotificationEntry.fromJson(
                    Map<String, dynamic>.from(e),
                  )),
        );
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('InAppNotificationsHub.restore failed: $e\n$st');
      }
    }
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      final slice = _entries.take(_maxStored).toList();
      await p.setString(
        _prefsKey,
        jsonEncode(slice.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('InAppNotificationsHub._persist failed: $e\n$st');
      }
    }
  }

  void show({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    final map = <String, String>{};
    payload?.forEach((k, v) => map[k] = '$v');
    final entry = InAppNotificationEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      at: DateTime.now(),
      payload: map,
    );
    _entries.insert(0, entry);
    while (_entries.length > _maxStored) {
      _entries.removeLast();
    }
    notifyListeners();
    _persist();
  }

  void dismiss(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    _persist();
  }

  Future<void> clear() async {
    _entries.clear();
    _restored = false;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_prefsKey);
    } catch (_) {}
  }
}
