import 'package:flutter/material.dart';
import 'package:grocery_app/app_scope.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/providers/admin_orders_provider.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/providers/product_ratings_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/home_screen_tiles_provider.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/services/pull_refresh_extras.dart';
import 'package:provider/provider.dart';

/// Shared pull-to-refresh work for customer + admin builds (best-effort per provider).
class AppWideRefresh {
  AppWideRefresh._();

  static Future<void> refresh(BuildContext context) async {
    if (!context.mounted) return;

    final scope = AppScope.of(context);
    final products = context.read<ProductsProvider>();
    final homeTiles = context.read<HomeScreenTilesProvider>();
    final categories = context.read<CategoriesProvider>();
    final ratings = context.read<ProductRatingsProvider>();
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final orders = context.read<OrdersProvider>();
    final adminOrders = context.read<AdminOrdersProvider>();

    await products.fetchProducts(
      includeHiddenFromCatalog: !scope.isCustomerApp,
    );

    try {
      await homeTiles.fetchTiles();
    } catch (_) {}

    try {
      await categories.fetchCategories();
    } catch (_) {}

    try {
      await ratings.refresh();
    } catch (_) {}

    final user = authInstance.currentUser;
    if (user == null) return;

    try {
      await cart.fetchCart();
    } catch (_) {}

    try {
      await wishlist.fetchWishlist();
    } catch (_) {}

    try {
      await orders.fetchOrders();
    } catch (_) {}

    if (!scope.isCustomerApp) {
      try {
        await adminOrders.refresh();
      } catch (_) {}
    }

    await PullRefreshExtras.runRegistered();
  }
}
