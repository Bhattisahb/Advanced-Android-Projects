/// POS Repository
/// Business logic for cart, billing, and checkout operations
/// Handles cart management, discounts, taxes, and sales creation

import 'package:flutter/material.dart';
import 'package:pos_app/data/models/cart_item_model.dart';
import 'package:pos_app/data/models/sale_model.dart';
import 'package:pos_app/data/models/sale_item_model.dart';
import 'package:pos_app/data/models/ledger_entry_model.dart';
import 'package:pos_app/data/local/sale_dao.dart';
import 'package:pos_app/data/local/ledger_entry_dao.dart';
import 'package:pos_app/data/repositories/inventory_repository.dart';
import 'package:pos_app/core/services/transaction_service.dart';

class POSRepository extends ChangeNotifier {
  final SaleDAO _saleDAO = SaleDAO();
  final LedgerEntryDAO _ledgerDAO = LedgerEntryDAO();
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final TransactionService _transactionService = TransactionService();

  /// In-memory cart for current session
  List<CartItem> _cart = [];

  /// Getters
  List<CartItem> get cart => _cart;
  int get itemCount => _cart.length;

  /// Get subtotal (before tax and discount)
  double get subtotal => _cart.fold<double>(
        0,
        (sum, item) => sum + item.lineTotal,
      );

  /// Calculate discount amount
  double calculateDiscountAmount(double discountPercentage) {
    return subtotal * (discountPercentage / 100);
  }

  /// Add product to cart
  void addToCart(CartItem item) {
    // Check if product already in cart
    final existingIndex = _cart.indexWhere(
      (c) => c.productId == item.productId,
    );

    if (existingIndex >= 0) {
      // Increment quantity
      _cart[existingIndex] = _cart[existingIndex].copyWith(
        quantity: _cart[existingIndex].quantity + item.quantity,
      );
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  /// Remove item from cart
  void removeFromCart(int productId) {
    _cart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(int productId, int newQuantity) {
    final index = _cart.indexWhere((c) => c.productId == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  /// Override price for an item
  void overridePrice(int productId, double newPrice) {
    final index = _cart.indexWhere((c) => c.productId == productId);
    if (index >= 0) {
      _cart[index] = _cart[index].copyWith(priceOverride: newPrice);
      notifyListeners();
    }
  }

  /// Clear cart
  void clearCart() {
    _cart = [];
    notifyListeners();
  }

  /// Get cart item
  CartItem? getCartItem(int productId) {
    try {
      return _cart.firstWhere((c) => c.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Checkout and create sale
  /// Returns sale ID on success
  Future<int> checkout({
    required int? customerId,
    required double discountPercentage,
    required double taxPercentage,
    required String paymentMethod,
  }) async {
    // Validation checks
    if (_cart.isEmpty) {
      throw 'Cart is empty';
    }

    // Validate percentages
    if (discountPercentage < 0 || discountPercentage > 100) {
      throw 'Discount percentage must be between 0 and 100';
    }
    if (taxPercentage < 0 || taxPercentage > 100) {
      throw 'Tax percentage must be between 0 and 100';
    }

    // Validate payment method
    if (!['CASH', 'CARD', 'CREDIT'].contains(paymentMethod)) {
      throw 'Invalid payment method: $paymentMethod';
    }

    // Validate customer for CREDIT payments
    if (paymentMethod == 'CREDIT' && customerId == null) {
      throw 'Customer must be selected for CREDIT payment';
    }

    final subtotalAmount = subtotal;
    final discountAmount = calculateDiscountAmount(discountPercentage);
    final amountAfterDiscount = subtotalAmount - discountAmount;
    final taxAmount = amountAfterDiscount * (taxPercentage / 100);
    final totalAmount = amountAfterDiscount + taxAmount;

    // Validate calculated amounts
    if (totalAmount <= 0) {
      throw 'Invalid order total. Total amount must be greater than 0';
    }

    // Create sale
    final sale = Sale(
      customerId: customerId,
      subtotal: subtotalAmount,
      discountAmount: discountAmount,
      discountPercentage: discountPercentage,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      status: 'COMPLETED',
      paymentMethod: paymentMethod,
      synced: false,
      createdAt: DateTime.now(),
    );

    // Save sale in transaction with timeout
    int saleId;
    try {
      saleId = await _saleDAO.addSale(sale).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Sale creation timeout'),
      );
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }

    try {
      // Save sale items
      for (final item in _cart) {
        final saleItem = SaleItem(
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,
          productSku: item.productSku,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          lineTotal: item.lineTotal,
          createdAt: DateTime.now(),
        );
        await _saleDAO.addSaleItem(saleItem).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Sale item creation timeout'),
        );

        // Update stock (Stock OUT) with timeout
        await _inventoryRepository.addStockOut(
          productId: item.productId,
          quantity: item.quantity,
          reason: 'Sale #$saleId',
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Stock update timeout'),
        );
      }

      // Add ledger entry for customer if applicable
      if (customerId != null) {
        final ledgerEntry = LedgerEntry(
          customerId: customerId,
          type: 'DEBIT',
          amount: totalAmount,
          saleId: saleId,
          description: 'Sale #$saleId',
          createdAt: DateTime.now(),
        );
        await _ledgerDAO.addEntry(ledgerEntry).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Ledger entry timeout'),
        );
      }

      // Clear cart after successful checkout
      clearCart();

      // Notify listeners about the new transaction
      _transactionService.notifyNewTransaction();

      return saleId;
    } catch (e) {
      // Rollback - delete sale if items failed
      try {
        await _saleDAO.deleteSale(saleId).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Rollback timeout'),
        );
      } catch (rollbackError) {
        throw Exception('Checkout failed and rollback failed: Original: $e, Rollback: $rollbackError');
      }
      rethrow;
    }
  }

  /// Get daily sales
  Future<List<Sale>> getDailySales(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _saleDAO.getAllSales(startDate: startOfDay, endDate: endOfDay);
  }

  /// Get daily sales amount
  Future<double> getDailySalesAmount(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _saleDAO.getTotalSalesAmount(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Get sale by ID
  Future<Sale?> getSaleById(int saleId) async {
    return _saleDAO.getSaleById(saleId);
  }

  /// Get sale items
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    return _saleDAO.getSaleItems(saleId);
  }
}
