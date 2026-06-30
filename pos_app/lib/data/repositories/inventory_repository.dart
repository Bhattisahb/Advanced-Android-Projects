/// Inventory Repository
/// Manages stock operations with transactional guarantees
/// Handles Stock IN, Stock OUT, and maintains audit trail
/// Ensures data integrity with atomic transactions

import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/models/stock_history_model.dart';
import 'package:pos_app/data/local/product_dao.dart';
import 'package:pos_app/data/local/stock_history_dao.dart';
import 'package:pos_app/data/local/database_helper.dart';

class InventoryRepository {
  final ProductDao _productDao = ProductDao();
  final StockHistoryDao _historyDao = StockHistoryDao();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Add stock IN transaction (purchase/receipt)
  /// Transactional: both product update and history record succeed or fail together
  Future<void> addStockIn({
    required int productId,
    required int quantity,
    String? reason,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    await _dbHelper.transaction((txn) async {
      // Get current product using transaction
      final result = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (result.isEmpty) {
        throw Exception('Product not found');
      }

      final product = Product.fromJson(result.first);

      // Update stock
      final newQuantity = product.stockQuantity + quantity;
      await txn.update(
        'products',
        {
          'stockQuantity': newQuantity,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      // Record history
      final history = StockHistory(
        productId: productId,
        changeType: StockChangeType.stockIn,
        quantity: quantity,
        reason: reason ?? 'Stock received',
        timestamp: DateTime.now(),
      );

      await txn.insert('stock_history', history.toJson());
      return null;
    });
  }

  /// Remove stock OUT transaction (sale/usage)
  /// Transactional: both product update and history record succeed or fail together
  Future<void> addStockOut({
    required int productId,
    required int quantity,
    String? reason,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    await _dbHelper.transaction((txn) async {
      // Get current product using transaction
      final result = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (result.isEmpty) {
        throw Exception('Product not found');
      }

      final product = Product.fromJson(result.first);

      // Check sufficient stock
      if (product.stockQuantity < quantity) {
        throw Exception(
          'Insufficient stock. Available: ${product.stockQuantity}, Required: $quantity',
        );
      }

      // Update stock
      final newQuantity = product.stockQuantity - quantity;
      await txn.update(
        'products',
        {
          'stockQuantity': newQuantity,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      // Record history
      final history = StockHistory(
        productId: productId,
        changeType: StockChangeType.stockOut,
        quantity: quantity,
        reason: reason ?? 'Stock issued',
        timestamp: DateTime.now(),
      );

      await txn.insert('stock_history', history.toJson());
      return null;
    });
  }

  /// Stock adjustment (inventory reconciliation)
  /// Can increase or decrease stock based on adjustment value
  Future<void> adjustStock({
    required int productId,
    required int adjustment,
    String? reason,
  }) async {
    if (adjustment == 0) {
      throw Exception('Adjustment cannot be zero');
    }

    await _dbHelper.transaction((txn) async {
      // Get current product using transaction
      final result = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (result.isEmpty) {
        throw Exception('Product not found');
      }

      final product = Product.fromJson(result.first);

      final newQuantity = product.stockQuantity + adjustment;

      // Prevent negative stock
      if (newQuantity < 0) {
        throw Exception(
          'Adjustment would result in negative stock. Current: ${product.stockQuantity}, Adjustment: $adjustment',
        );
      }

      // Update stock
      await txn.update(
        'products',
        {
          'stockQuantity': newQuantity,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      // Record history
      final changeType = adjustment > 0
          ? StockChangeType.stockIn
          : StockChangeType.stockOut;

      final history = StockHistory(
        productId: productId,
        changeType: changeType,
        quantity: adjustment.abs(),
        reason: reason ?? 'Stock adjustment',
        timestamp: DateTime.now(),
      );

      await txn.insert('stock_history', history.toJson());
      return null;
    });
  }

  /// Get stock history for a product
  Future<List<StockHistory>> getProductHistory(int productId) async {
    return _historyDao.getProductHistory(productId);
  }

  /// Get recent stock history
  Future<List<StockHistory>> getRecentHistory({int limit = 50}) async {
    return _historyDao.getRecentHistory(limit: limit);
  }

  /// Get product stock status
  Future<Product?> getProductStock(int productId) async {
    return _productDao.getProductById(productId);
  }

  /// Get all low stock products
  Future<List<Product>> getLowStockProducts(int threshold) async {
    return _productDao.getLowStockProducts(threshold);
  }

  /// Get stock summary for a product
  Future<Map<String, int>> getProductStockSummary(int productId) async {
    return _historyDao.getProductStockSummary(productId);
  }
}
