import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/models/orders_model.dart';

class OrdersProvider with ChangeNotifier {
  static List<OrderModel> _orders = [];
  List<OrderModel> get getOrders {
    return _orders;
  }

  Future<void> fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();

    _orders = [];
    for (final element in ordersSnapshot.docs) {
      final data = element.data();
      _orders.add(
        OrderModel(
          orderId: (data['orderId'] ?? element.id).toString(),
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
              (data['fulfillmentStatus'] ?? FulfillmentStatuses.pending)
                  .toString(),
          shippingAddress:
              (data['shippingAddress'] ?? data['shipping_address'] ?? '')
                  .toString(),
          adminNotes: (data['adminNotes'] ?? data['admin_notes'] ?? '')
              .toString(),
        ),
      );
    }
    _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    notifyListeners();
  }
}
