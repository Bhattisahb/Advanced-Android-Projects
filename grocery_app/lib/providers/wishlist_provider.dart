import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/models/wishlist_model.dart';

class WishlistProvider with ChangeNotifier {
  Map<String, WishlistModel> _wishlistItems = {};

  Map<String, WishlistModel> get getWishlistItems {
    return _wishlistItems;
  }

  final userCollection = FirebaseFirestore.instance.collection('users');

  Future<void> fetchWishlist() async {
    final User? user = authInstance.currentUser;
    _wishlistItems.clear();
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

    final raw = data['userWish'];
    if (raw is! List) {
      notifyListeners();
      return;
    }

    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final productId = map['productId']?.toString();
      if (productId == null || productId.isEmpty) continue;
      _wishlistItems[productId] = WishlistModel(
        id: map['wishlistId']?.toString() ?? '',
        productId: productId,
      );
    }
    notifyListeners();
  }

  Future<void> removeOneItem({
    required String wishlistId,
    required String productId,
  }) async {
    final User? user = authInstance.currentUser;
    await userCollection.doc(user!.uid).update({
      'userWish': FieldValue.arrayRemove([
        {
          'wishlistId': wishlistId,
          'productId': productId,
        }
      ])
    });
    _wishlistItems.remove(productId);
    await fetchWishlist();
  }

  Future<void> clearOnlineWishlist() async {
    final User? user = authInstance.currentUser;
    await userCollection.doc(user!.uid).update({
      'userWish': [],
    });
    _wishlistItems.clear();
    notifyListeners();
  }

  void clearLocalWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
