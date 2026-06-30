/// Product Repository
/// Implements repository pattern to abstract data source
/// Provides high-level API for product operations
/// Can easily swap SQLite for Firebase or other backend

import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/local/product_dao.dart';
import 'package:pos_app/core/constants/app_constants.dart';

class ProductRepository {
  final ProductDao _productDao = ProductDao();

  /// Add new product
  Future<int> addProduct({
    required String name,
    required String sku,
    required double price,
    required double cost,
    required String category,
    required int stockQuantity,
  }) async {
    // Validate input
    if (name.isEmpty || sku.isEmpty) {
      throw Exception('Product name and SKU cannot be empty');
    }
    if (price <= 0) {
      throw Exception('Price must be greater than 0');
    }
    if (cost < 0) {
      throw Exception('Cost cannot be negative');
    }

    // Check SKU uniqueness
    final existing = await _productDao.getProductBySku(sku);
    if (existing != null) {
      throw Exception('A product with this SKU already exists');
    }

    final product = Product(
      name: name,
      sku: sku,
      price: price,
      cost: cost,
      category: category,
      stockQuantity: stockQuantity,
      createdAt: DateTime.now(),
    );

    return _productDao.insertProduct(product);
  }

  /// Update existing product
  Future<void> updateProduct({
    required int id,
    required String name,
    required String sku,
    required double price,
    required double cost,
    required String category,
    required int stockQuantity,
  }) async {
    // Validate input
    if (name.isEmpty || sku.isEmpty) {
      throw Exception('Product name and SKU cannot be empty');
    }
    if (price <= 0) {
      throw Exception('Price must be greater than 0');
    }
    if (cost < 0) {
      throw Exception('Cost cannot be negative');
    }

    // Get existing product
    final existing = await _productDao.getProductById(id);
    if (existing == null) {
      throw Exception('Product not found');
    }

    // Check SKU uniqueness (excluding current product)
    final skuConflict = await _productDao.getProductBySku(sku);
    if (skuConflict != null && skuConflict.id != id) {
      throw Exception('A product with this SKU already exists');
    }

    final updated = Product(
      id: id,
      name: name,
      sku: sku,
      price: price,
      cost: cost,
      category: category,
      stockQuantity: stockQuantity,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    await _productDao.updateProduct(updated);
  }

  /// Get product by ID
  Future<Product?> getProduct(int id) async {
    return _productDao.getProductById(id);
  }

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    return _productDao.getAllProducts();
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    return _productDao.getProductsByCategory(category);
  }

  /// Get all low stock products
  Future<List<Product>> getLowStockProducts() async {
    return _productDao.getLowStockProducts(AppConstants.LOW_STOCK_THRESHOLD);
  }

  /// Search products by name or SKU
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      return getAllProducts();
    }
    return _productDao.searchProducts(query);
  }

  /// Delete product
  Future<void> deleteProduct(int id) async {
    final existing = await _productDao.getProductById(id);
    if (existing == null) {
      throw Exception('Product not found');
    }
    await _productDao.deleteProduct(id);
  }

  /// Get total product count
  Future<int> getProductCount() async {
    return _productDao.getProductCount();
  }
}
