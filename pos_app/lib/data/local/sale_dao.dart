/// Sale DAO
/// Data Access Object for sale/invoice operations
/// Handles CRUD and querying of sales and line items

import 'package:sqflite/sqflite.dart';
import 'package:pos_app/data/local/database_helper.dart';
import 'package:pos_app/data/models/sale_model.dart';
import 'package:pos_app/data/models/sale_item_model.dart';

class SaleDAO {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get all sales with optional date range filter
  Future<List<Sale>> getAllSales({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      where =
          'createdAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    }

    final results = await db.query(
      'sales',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => Sale.fromMap(map)).toList();
  }

  /// Get sale by ID
  Future<Sale?> getSaleById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Sale.fromMap(results.first);
  }

  /// Get sales for a specific customer
  Future<List<Sale>> getCustomerSales(int customerId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'sales',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => Sale.fromMap(map)).toList();
  }

  /// Add new sale and get the ID
  Future<int> addSale(Sale sale) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert(
        'sales',
        sale.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error adding sale: $e');
      rethrow;
    }
  }

  /// Update sale
  Future<void> updateSale(Sale sale) async {
    final db = await _dbHelper.database;
    await db.update(
      'sales',
      sale.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  /// Delete sale (and cascade to sale_items)
  Future<void> deleteSale(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('sale_items', where: 'saleId = ?', whereArgs: [id]);
      await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
      return null;
    });
  }

  /// Add sale item (line item)
  Future<int> addSaleItem(SaleItem item) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert(
        'sale_items',
        item.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error adding sale item: $e');
      rethrow;
    }
  }

  /// Get all items for a sale
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'sale_items',
      where: 'saleId = ?',
      whereArgs: [saleId],
      orderBy: 'createdAt ASC',
    );
    return results.map((map) => SaleItem.fromMap(map)).toList();
  }

  /// Get total sales amount for date range
  Future<double> getTotalSalesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      where = 'createdAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    }

    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM sales ${where.isNotEmpty ? 'WHERE $where' : ''}',
      whereArgs.isEmpty ? null : whereArgs,
    );

    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  /// Get count of sales for date range
  Future<int> getSalesCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      where = 'createdAt BETWEEN ? AND ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales ${where.isNotEmpty ? 'WHERE $where' : ''}',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// Get unsync sales (for offline-first syncing)
  Future<List<Sale>> getUnsyncedSales() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'sales',
      where: 'synced = 0',
      orderBy: 'createdAt ASC',
    );
    return results.map((map) => Sale.fromMap(map)).toList();
  }

  /// Mark sale as synced
  Future<void> markAsSynced(int saleId) async {
    final db = await _dbHelper.database;
    await db.update(
      'sales',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }
}
