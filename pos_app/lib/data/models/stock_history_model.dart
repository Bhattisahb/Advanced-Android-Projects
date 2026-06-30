/// Stock History Model
/// Records every stock change with type (IN/OUT), quantity, and timestamp
/// Enables audit trail and inventory reconciliation

enum StockChangeType {
  stockIn('Stock In'),
  stockOut('Stock Out'),
  adjustment('Adjustment');

  final String displayName;
  const StockChangeType(this.displayName);
}

class StockHistory {
  final int? id;
  final int productId;
  final StockChangeType changeType;
  final int quantity;
  final String? reason;
  final DateTime timestamp;

  StockHistory({
    this.id,
    required this.productId,
    required this.changeType,
    required this.quantity,
    this.reason,
    required this.timestamp,
  });

  /// Convert StockHistory to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'changeType': changeType.name,
      'quantity': quantity,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create StockHistory from JSON (database row)
  factory StockHistory.fromJson(Map<String, dynamic> json) {
    return StockHistory(
      id: json['id'] as int?,
      productId: json['productId'] as int,
      changeType: StockChangeType.values.byName(json['changeType'] as String),
      quantity: json['quantity'] as int,
      reason: json['reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create a copy with modified fields
  StockHistory copyWith({
    int? id,
    int? productId,
    StockChangeType? changeType,
    int? quantity,
    String? reason,
    DateTime? timestamp,
  }) {
    return StockHistory(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      changeType: changeType ?? this.changeType,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'StockHistory(id: $id, productId: $productId, '
        'changeType: ${changeType.displayName}, quantity: $quantity, '
        'timestamp: $timestamp)';
  }
}
