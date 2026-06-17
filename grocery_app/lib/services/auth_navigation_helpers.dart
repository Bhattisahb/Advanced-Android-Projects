import 'package:flutter/material.dart';
import 'package:grocery_app/auth_navigation.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/product_ratings_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/route_paths.dart';
import 'package:grocery_app/screens/btm_bar.dart';
import 'package:grocery_app/services/push_notification_service.dart';
import 'package:grocery_app/services/guest_session.dart';
import 'package:provider/provider.dart';

/// Avoid stacking routes (e.g. [BottomBar] under [Login]) after auth changes.
abstract final class AuthNavigationHelpers {
  AuthNavigationHelpers._();

  /// Replace entire stack with the correct post-auth bootstrap ([FetchScreen] or [AdminFetchScreen]).
  static void replaceStackWithPostAuthHome(BuildContext context) {
    if (!context.mounted) return;
    GuestSession.exit();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (ctx) => postAuthHome(ctx),
      ),
      (route) => false,
    );
  }

  /// Signs out and runs customer splash flow ([FetchScreen]), which clears guest cart/wishlist locals when signed out.
  static Future<void> signOutCustomer(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    await PushNotificationService.onSignedOut();
    GuestSession.exit();
    await authInstance.signOut();
    cartProvider.clearLocalCart();
    wishlistProvider.clearLocalWishlist();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RoutePaths.login,
      (route) => false,
    );
  }

  static Future<void> enterGuestCustomer(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final ratingsProvider =
        Provider.of<ProductRatingsProvider>(context, listen: false);
    await PushNotificationService.onSignedOut();
    await authInstance.signOut();
    GuestSession.enter();
    cartProvider.clearLocalCart();
    wishlistProvider.clearLocalWishlist();
    await productsProvider.fetchProducts();
    try {
      await ratingsProvider.refresh();
    } catch (_) {
      // Reviews are public data, but catalog browsing should still work if
      // aggregate refresh is blocked or offline.
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const BottomBarScreen()),
      (route) => false,
    );
  }
}
