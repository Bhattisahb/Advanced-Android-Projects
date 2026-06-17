import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';
import 'package:grocery_app/models/orders_model.dart';

/// One checkout batch (shared `groupOrderId`) or a legacy single-line order.
class AdminGroupedOrder {
  AdminGroupedOrder({
    required this.groupKey,
    required this.lines,
  }) : assert(lines.isNotEmpty);

  final String groupKey;
  final List<OrderModel> lines;

  String get userId => lines.first.userId;
  String get userName => lines.first.userName;
  Timestamp get orderDate {
    var newest = lines.first.orderDate;
    for (final l in lines.skip(1)) {
      if (l.orderDate.compareTo(newest) > 0) newest = l.orderDate;
    }
    return newest;
  }
  String get totalOrderPrice => lines.first.totalOrderPrice;
  String get fulfillmentStatus =>
      lines.first.fulfillmentStatus.isEmpty
          ? FulfillmentStatuses.pending
          : lines.first.fulfillmentStatus;

  /// Same convention as fulfillment: first line represents the batch.
  String? get paymentStatus => lines.first.paymentStatus;

  bool get paymentReceived => OrderPaymentStatuses.isPaid(paymentStatus);

  String? get paymentReceivedVia => lines.first.paymentReceivedVia;

  bool matchesFilter(String? statusFilter) {
    if (statusFilter == null || statusFilter.isEmpty) return true;
    final s = fulfillmentStatus;
    return s == statusFilter;
  }

  bool matchesUser(String? userIdFilter) {
    if (userIdFilter == null || userIdFilter.isEmpty) return true;
    return userId == userIdFilter;
  }
}

class AdminOrdersProvider with ChangeNotifier {
  List<AdminGroupedOrder> _groups = [];
  bool _loading = false;
  String? _error;

  List<AdminGroupedOrder> get groups => List.unmodifiable(_groups);
  bool get loading => _loading;
  String? get error => _error;

  List<AdminGroupedOrder> groupedOrdersFiltered({
    String? statusFilter,
    String? userIdFilter,
  }) {
    return _groups
        .where((g) =>
            g.matchesFilter(statusFilter) && g.matchesUser(userIdFilter))
        .toList();
  }

  /// Clears in-memory batches after sign-out (next login runs [refresh] again).
  void resetSession() {
    _groups = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final snap =
          await FirebaseFirestore.instance.collection('orders').limit(500).get();

      final lines = snap.docs.map((doc) => _docToOrder(doc)).toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

      final Map<String, List<OrderModel>> map = {};
      for (final line in lines) {
        final key = (line.groupOrderId != null &&
                line.groupOrderId!.trim().isNotEmpty)
            ? line.groupOrderId!.trim()
            : line.orderId;
        map.putIfAbsent(key, () => []).add(line);
      }

      _groups = map.entries
          .map((e) => AdminGroupedOrder(groupKey: e.key, lines: e.value))
          .toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('AdminOrdersProvider.refresh failed: $e\n$st');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _refsForGroupKey(
    String groupKey,
  ) async {
    final col = FirebaseFirestore.instance.collection('orders');
    final refs = <DocumentReference<Map<String, dynamic>>>[];

    final byGroup =
        await col.where('groupOrderId', isEqualTo: groupKey).get();
    if (byGroup.docs.isNotEmpty) {
      refs.addAll(byGroup.docs.map((e) => e.reference));
    } else {
      final byOrderId =
          await col.where('orderId', isEqualTo: groupKey).get();
      if (byOrderId.docs.isNotEmpty) {
        refs.addAll(byOrderId.docs.map((e) => e.reference));
      } else {
        final docRef = col.doc(groupKey);
        final snap = await docRef.get();
        if (snap.exists) {
          refs.add(docRef);
        }
      }
    }
    return refs;
  }

  Future<void> updateGroupFulfillment({
    required String groupKey,
    required String fulfillmentStatus,
    required String adminNotes,
  }) async {
    final refs = await _refsForGroupKey(groupKey);
    if (refs.isEmpty) {
      throw StateError('No order documents found for group $groupKey');
    }

    final batch = FirebaseFirestore.instance.batch();
    final now = FieldValue.serverTimestamp();
    for (final r in refs) {
      batch.update(r, {
        'fulfillmentStatus': fulfillmentStatus,
        'adminNotes': adminNotes,
        'fulfillmentUpdatedAt': now,
      });
    }
    await batch.commit();
    await refresh();
  }

  /// [paymentReceivedVia] must be one of [PaymentReceivedVia.all].
  Future<void> markGroupPaymentReceived({
    required String groupKey,
    required String paymentReceivedVia,
  }) async {
    if (!PaymentReceivedVia.all.contains(paymentReceivedVia)) {
      throw ArgumentError.value(
        paymentReceivedVia,
        'paymentReceivedVia',
        'Use PaymentReceivedVia.bank, jazzcash, or easypaisa',
      );
    }
    final refs = await _refsForGroupKey(groupKey);
    if (refs.isEmpty) {
      throw StateError('No order documents found for group $groupKey');
    }

    final batch = FirebaseFirestore.instance.batch();
    final now = FieldValue.serverTimestamp();
    for (final r in refs) {
      batch.update(r, {
        'paymentStatus': OrderPaymentStatuses.paid,
        'paidAt': now,
        'paymentReceivedVia': paymentReceivedVia,
      });
    }
    await batch.commit();
    await refresh();
  }

  OrderModel _docToOrder(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return OrderModel(
      orderId: (data['orderId'] ?? doc.id).toString(),
      userId: (data['userId'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      price: (data['price'] ?? 0).toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      quantity: (data['quantity'] ?? 0).toString(),
      orderDate: data['orderDate'] is Timestamp
          ? data['orderDate'] as Timestamp
          : Timestamp.now(),
      groupOrderId: data['groupOrderId'] as String?,
      totalOrderPrice:
          (data['totalPrice'] ?? data['price'] ?? 0).toString(),
      paymentStatus: data['paymentStatus'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      paidAt:
          data['paidAt'] is Timestamp ? data['paidAt'] as Timestamp : null,
      paymentReceivedVia: data['paymentReceivedVia'] as String?,
      fulfillmentStatus:
          (data['fulfillmentStatus'] ?? FulfillmentStatuses.pending).toString(),
      shippingAddress:
          (data['shippingAddress'] ?? data['shipping_address'] ?? '').toString(),
      adminNotes:
          (data['adminNotes'] ?? data['admin_notes'] ?? '').toString(),
    );
  }
}
