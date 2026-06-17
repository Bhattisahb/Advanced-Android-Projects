import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/models/cart_model.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartModel> _cartItems = {};

  Map<String, CartModel> get getCartItems {
    return _cartItems;
  }

  final userCollection = FirebaseFirestore.instance.collection('users');
  Future<void> fetchCart() async {
    final User? user = authInstance.currentUser;
    _cartItems.clear();
    if (user == null) {
      notifyListeners();
      return;
    }

    final DocumentSnapshot userDoc = await userCollection.doc(user.uid).get();
    if (!userDoc.exists) {
      notifyListeners();
      return;
    }

    final Object? blob = userDoc.data();
    final Map<String, dynamic>? data = blob is Map<String, dynamic>
        ? blob
        : blob is Map
            ? Map<String, dynamic>.from(blob)
            : null;
    if (data == null) {
      notifyListeners();
      return;
    }

    final raw = data['userCart'];
    if (raw is! List) {
      notifyListeners();
      return;
    }

    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final productId = map['productId']?.toString();
      if (productId == null || productId.isEmpty) continue;
      final qtyRaw = map['quantity'];
      final quantity = qtyRaw is int
          ? qtyRaw
          : qtyRaw is num
              ? qtyRaw.toInt()
              : int.tryParse(qtyRaw?.toString() ?? '') ?? 1;
      _cartItems[productId] = CartModel(
        id: map['cartId']?.toString() ?? '',
        productId: productId,
        quantity: quantity,
      );
    }
    notifyListeners();
  }

  void reduceQuantityByOne(String productId) {
    _cartItems.update(
      productId,
      (value) => CartModel(
        id: value.id,
        productId: productId,
        quantity: value.quantity - 1,
      ),
    );

    notifyListeners();
  }

  void increaseQuantityByOne(String productId) {
    _cartItems.update(
      productId,
      (value) => CartModel(
        id: value.id,
        productId: productId,
        quantity: value.quantity + 1,
      ),
    );
    notifyListeners();
  }

  Future<void> removeOneItem(
      {required String cartId,
      required String productId,
      required int quantity}) async {
    final User? user = authInstance.currentUser;
    await userCollection.doc(user!.uid).update({
      'userCart': FieldValue.arrayRemove([
        {'cartId': cartId, 'productId': productId, 'quantity': quantity}
      ])
    });
    _cartItems.remove(productId);
    await fetchCart();
  }

  Future<void> clearOnlineCart() async {
    final User? user = authInstance.currentUser;
    await userCollection.doc(user!.uid).update({
      'userCart': [],
    });
    _cartItems.clear();
    notifyListeners();
  }

  void clearLocalCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
