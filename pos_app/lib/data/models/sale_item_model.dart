/// Sale Item Model
/// Represents individual line items in a sale/invoice
/// Stores product info and quantity at time of sale

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final String productSku;
  final double unitPrice;
  final int quantity;
  final double lineTotal; // quantity * unitPrice
  final DateTime createdAt;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.createdAt,
  });

  /// Create a JSON-serializable map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'unitPrice': (unitPrice * 100).toInt(),
      'quantity': quantity,
      'lineTotal': (lineTotal * 100).toInt(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a SaleItem from database map
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['saleId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      productSku: map['productSku'] as String,
      unitPrice: ((map['unitPrice'] as num).toDouble()) / 100,
      quantity: map['quantity'] as int,
      lineTotal: ((map['lineTotal'] as num).toDouble()) / 100,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Copy with modifications
  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    String? productSku,
    double? unitPrice,
    int? quantity,
    double? lineTotal,
    DateTime? createdAt,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
