/// Stock History Data Access Object (DAO)
/// Handles all operations for stock history in SQLite
/// Maintains audit trail of all inventory changes

import 'package:sqflite/sqflite.dart';
import 'package:pos_app/data/local/database_helper.dart';
import 'package:pos_app/data/models/stock_history_model.dart';

class StockHistoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert stock history record
  /// Returns the ID of the inserted record
  Future<int> insertStockHistory(StockHistory history) async {
    final db = await _dbHelper.database;
    return db.insert(
      'stock_history',
      history.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get stock history by ID
  Future<StockHistory?> getStockHistoryById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_history',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return StockHistory.fromJson(result.first);
  }

  /// Get all stock history records for a product
  Future<List<StockHistory>> getProductHistory(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_history',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => StockHistory.fromJson(json)).toList();
  }

  /// Get all stock history records
  Future<List<StockHistory>> getAllStockHistory() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_history',
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => StockHistory.fromJson(json)).toList();
  }

  /// Alias for getAllStockHistory (used by backup service)
  Future<List<StockHistory>> getAll() async {
    return getAllStockHistory();
  }

  /// Get recent stock history for all products
  /// Useful for dashboard/audit log
  Future<List<StockHistory>> getRecentHistory({int limit = 50}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return result.map((json) => StockHistory.fromJson(json)).toList();
  }

  /// Get stock history for a product within date range
  Future<List<StockHistory>> getHistoryByDateRange(
    int productId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_history',
      where:
          'productId = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        productId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => StockHistory.fromJson(json)).toList();
  }

  /// Get stock history by change type
  Future<List<StockHistory>> getHistoryByChangeType(
    StockChangeType changeType,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_history',
      where: 'changeType = ?',
      whereArgs: [changeType.name],
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => StockHistory.fromJson(json)).toList();
  }

  /// Delete stock history record
  Future<int> deleteStockHistory(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'stock_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all history for a product
  /// Used when deleting products
  Future<int> deleteProductHistory(int productId) async {
    final db = await _dbHelper.database;
    return db.delete(
      'stock_history',
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  /// Get stock in/out summary for a product
  /// Returns total quantity added and removed
  Future<Map<String, int>> getProductStockSummary(int productId) async {
    final db = await _dbHelper.database;
    final history = await getProductHistory(productId);

    int totalIn = 0;
    int totalOut = 0;

    for (final record in history) {
      if (record.changeType == StockChangeType.stockIn) {
        totalIn += record.quantity;
      } else if (record.changeType == StockChangeType.stockOut) {
        totalOut += record.quantity;
      }
    }

    return {
      'totalIn': totalIn,
      'totalOut': totalOut,
    };
  }

  /// Delete all history (for cleanup/testing)
  Future<int> deleteAllHistory() async {
    final db = await _dbHelper.database;
    return db.delete('stock_history');
  }
}
