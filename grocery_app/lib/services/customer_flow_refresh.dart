import 'package:flutter/material.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:provider/provider.dart';

/// Refreshes providers after key shopper flows so UI matches Firestore immediately.
class CustomerFlowRefresh {
  CustomerFlowRefresh._();

  /// After cart checkout: orders list, cart snapshot, product catalog.
  static Future<void> afterFullCartCheckout(BuildContext context) async {
    if (!context.mounted) return;
    final orders = context.read<OrdersProvider>();
    final cart = context.read<CartProvider>();
    final products = context.read<ProductsProvider>();
    await Future.wait([
      orders.fetchOrders(),
      cart.fetchCart(),
      products.fetchProducts(includeHiddenFromCatalog: false),
    ]);
  }

  /// After single-product checkout (cart unchanged): orders + catalog.
  static Future<void> afterSingleProductCheckout(BuildContext context) async {
    if (!context.mounted) return;
    final orders = context.read<OrdersProvider>();
    final products = context.read<ProductsProvider>();
    await Future.wait([
      orders.fetchOrders(),
      products.fetchProducts(includeHiddenFromCatalog: false),
    ]);
  }
}
