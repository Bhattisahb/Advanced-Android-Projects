/// Sale Model
/// Represents a completed transaction/invoice
/// Stores summary and metadata for offline-first syncing

class Sale {
  final int? id;
  final int? customerId;
  final double subtotal; // Before tax and discount
  final double discountAmount;
  final double discountPercentage;
  final double taxAmount;
  final double totalAmount;
  final String status; // 'PENDING', 'COMPLETED', 'RETURNED'
  final String paymentMethod; // 'CASH', 'CARD', 'CREDIT'
  final bool synced; // For offline-first pattern
  final DateTime createdAt;
  final DateTime? updatedAt;

  Sale({
    this.id,
    this.customerId,
    required this.subtotal,
    required this.discountAmount,
    required this.discountPercentage,
    required this.taxAmount,
    required this.totalAmount,
    this.status = 'COMPLETED',
    this.paymentMethod = 'CASH',
    this.synced = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a JSON-serializable map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'subtotal': (subtotal * 100).toInt(),
      'discountAmount': (discountAmount * 100).toInt(),
      'discountPercentage': discountPercentage,
      'taxAmount': (taxAmount * 100).toInt(),
      'totalAmount': (totalAmount * 100).toInt(),
      'status': status,
      'paymentMethod': paymentMethod,
      'synced': synced ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a Sale from database map
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      customerId: map['customerId'] as int?,
      subtotal: ((map['subtotal'] as num).toDouble()) / 100,
      discountAmount: ((map['discountAmount'] as num).toDouble()) / 100,
      discountPercentage: (map['discountPercentage'] as num).toDouble(),
      taxAmount: ((map['taxAmount'] as num).toDouble()) / 100,
      totalAmount: ((map['totalAmount'] as num).toDouble()) / 100,
      status: map['status'] as String? ?? 'COMPLETED',
      paymentMethod: map['paymentMethod'] as String? ?? 'CASH',
      synced: (map['synced'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Copy with modifications
  Sale copyWith({
    int? id,
    int? customerId,
    double? subtotal,
    double? discountAmount,
    double? discountPercentage,
    double? taxAmount,
    double? totalAmount,
    String? status,
    String? paymentMethod,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
