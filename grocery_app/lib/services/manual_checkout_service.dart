import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:uuid/uuid.dart';

/// Checkout without a payment gateway: order is stored as awaiting manual confirmation.
class ManualCheckoutService {
  ManualCheckoutService._();

  static Future<void> submitPendingManualOrder({
    required User user,
    required CartProvider cartProvider,
    required ProductsProvider productProvider,
  }) async {
    final entries = cartProvider.getCartItems.entries.toList();
    if (entries.isEmpty) return;

    double total = 0;
    for (final e in entries) {
      final p = productProvider.findProdById(e.value.productId);
      total += (p.isOnSale ? p.salePrice : p.price) * e.value.quantity;
    }

    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final shippingRaw =
        userSnap.data()?['shipping-address'] ?? userSnap.data()?['shipping_address'];
    final shippingAddress =
        shippingRaw == null ? '' : shippingRaw.toString().trim();

    final batch = FirebaseFirestore.instance.batch();
    final ordersCol = FirebaseFirestore.instance.collection('orders');
    final groupOrderId = const Uuid().v4();

    for (final entry in entries) {
      final cartLine = entry.value;
      final product = productProvider.findProdById(cartLine.productId);
      final lineTotal =
          (product.isOnSale ? product.salePrice : product.price) * cartLine.quantity;
      final docRef = ordersCol.doc();

      batch.set(docRef, {
        'orderId': docRef.id,
        'groupOrderId': groupOrderId,
        'userId': user.uid,
        'productId': cartLine.productId,
        'price': lineTotal,
        'totalPrice': total,
        'quantity': cartLine.quantity,
        'imageUrl': product.imageUrl,
        'userName': user.displayName ?? user.email ?? 'Customer',
        'orderDate': Timestamp.now(),
        'paymentStatus': OrderPaymentStatuses.pendingPayment,
        'paymentMethod': 'manual_bank_wallet',
        'fulfillmentStatus': FulfillmentStatuses.pending,
        'shippingAddress': shippingAddress,
        'adminNotes': '',
      });
    }

    await batch.commit();
    await cartProvider.clearOnlineCart();
    cartProvider.clearLocalCart();
  }

  /// One product line only — leaves [CartProvider] untouched.
  static Future<void> submitPendingManualOrderSingleProduct({
    required User user,
    required ProductsProvider productProvider,
    required String productId,
    required int quantity,
  }) async {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be >= 1');
    }

    final product = productProvider.findProdById(productId);
    final unitPrice = product.isOnSale ? product.salePrice : product.price;
    final lineTotal = unitPrice * quantity;
    final total = lineTotal;

    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final shippingRaw =
        userSnap.data()?['shipping-address'] ?? userSnap.data()?['shipping_address'];
    final shippingAddress =
        shippingRaw == null ? '' : shippingRaw.toString().trim();

    final batch = FirebaseFirestore.instance.batch();
    final ordersCol = FirebaseFirestore.instance.collection('orders');
    final groupOrderId = const Uuid().v4();
    final docRef = ordersCol.doc();

    batch.set(docRef, {
      'orderId': docRef.id,
      'groupOrderId': groupOrderId,
      'userId': user.uid,
      'productId': productId,
      'price': lineTotal,
      'totalPrice': total,
      'quantity': quantity,
      'imageUrl': product.imageUrl,
      'userName': user.displayName ?? user.email ?? 'Customer',
      'orderDate': Timestamp.now(),
      'paymentStatus': OrderPaymentStatuses.pendingPayment,
      'paymentMethod': 'manual_bank_wallet',
      'fulfillmentStatus': FulfillmentStatuses.pending,
      'shippingAddress': shippingAddress,
      'adminNotes': '',
    });

    await batch.commit();
  }
}
