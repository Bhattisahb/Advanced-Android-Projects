/// Product Model
/// Represents a product with SKU, pricing, stock, and timestamps
/// Can be serialized to/from JSON for database storage

class Product {
  final int? id;
  final String name;
  final String sku;
  final double price;
  final double cost;
  final String category;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.cost,
    required this.category,
    required this.stockQuantity,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert Product to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': (price * 100).toInt(),
      'cost': (cost * 100).toInt(),
      'category': category,
      'stockQuantity': stockQuantity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create Product from JSON (database row)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String,
      sku: json['sku'] as String,
      price: ((json['price'] as num).toDouble()) / 100,
      cost: ((json['cost'] as num).toDouble()) / 100,
      category: json['category'] as String,
      stockQuantity: json['stockQuantity'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Create a copy with modified fields
  Product copyWith({
    int? id,
    String? name,
    String? sku,
    double? price,
    double? cost,
    String? category,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate profit margin percentage
  double get profitMargin {
    if (price == 0) return 0;
    return ((price - cost) / price) * 100;
  }

  /// Check if stock is low (below threshold)
  bool get isLowStock => stockQuantity < 5;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, sku: $sku, price: $price, '
        'cost: $cost, category: $category, stockQuantity: $stockQuantity)';
  }
}
