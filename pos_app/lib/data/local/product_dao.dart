/// Product Data Access Object (DAO)
/// Handles all CRUD operations for products in SQLite
/// Provides clean interface for database operations

import 'package:sqflite/sqflite.dart';
import 'package:pos_app/data/local/database_helper.dart';
import 'package:pos_app/data/models/product_model.dart';

class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert a new product
  /// Returns the ID of the inserted product
  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    return db.insert(
      'products',
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get product by ID
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Product.fromJson(result.first);
  }

  /// Get product by SKU
  Future<Product?> getProductBySku(String sku) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
    );

    if (result.isEmpty) return null;
    return Product.fromJson(result.first);
  }

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'products',
        orderBy: 'name ASC',
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout querying products - database may be locked');
        },
      );

      return result.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all products: $e');
      rethrow;
    }
  }

  /// Get all products with low stock
  Future<List<Product>> getLowStockProducts(int threshold) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'stockQuantity < ?',
      whereArgs: [threshold],
      orderBy: 'stockQuantity ASC',
    );

    return result.map((json) => Product.fromJson(json)).toList();
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );

    return result.map((json) => Product.fromJson(json)).toList();
  }

  /// Update product
  /// Returns number of rows updated
  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return db.update(
      'products',
      {
        ...product.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Update only stock quantity
  /// Used for inventory operations
  Future<int> updateStockQuantity(int productId, int newQuantity) async {
    final db = await _dbHelper.database;
    return db.update(
      'products',
      {
        'stockQuantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  /// Delete product
  /// Returns number of rows deleted
  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total count of products
  Future<int> getProductCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Search products by name or SKU
  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final lowerQuery = query.toLowerCase();
    final result = await db.query(
      'products',
      where: 'LOWER(name) LIKE ? OR LOWER(sku) LIKE ?',
      whereArgs: ['%$lowerQuery%', '%$lowerQuery%'],
      orderBy: 'name ASC',
    );

    return result.map((json) => Product.fromJson(json)).toList();
  }

  /// Delete all products (for cleanup/testing)
  Future<int> deleteAllProducts() async {
    final db = await _dbHelper.database;
    return db.delete('products');
  }
}
