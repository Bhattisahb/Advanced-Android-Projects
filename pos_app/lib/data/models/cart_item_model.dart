/// Cart Item Model
/// Represents a product in the shopping cart with quantity and pricing
/// Supports dynamic price override and discount calculations

class CartItem {
  final int productId;
  final String productName;
  final String productSku;
  final double basePrice;
  int quantity;
  double? priceOverride; // Optional price override per item

  CartItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.basePrice,
    this.quantity = 1,
    this.priceOverride,
  });

  /// Get effective price per unit (override or base price)
  double get unitPrice => priceOverride ?? basePrice;

  /// Get total price for this line (quantity * unit price)
  double get lineTotal => quantity * unitPrice;

  /// Create a copy with optional modifications
  CartItem copyWith({
    int? productId,
    String? productName,
    String? productSku,
    double? basePrice,
    int? quantity,
    double? priceOverride,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      basePrice: basePrice ?? this.basePrice,
      quantity: quantity ?? this.quantity,
      priceOverride: priceOverride ?? this.priceOverride,
    );
  }
}
