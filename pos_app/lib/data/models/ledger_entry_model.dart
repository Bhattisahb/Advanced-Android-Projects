/// Ledger Entry Model
/// Tracks customer credit/debit transactions
/// Used for outstanding balance and payment tracking

class LedgerEntry {
  final int? id;
  final int customerId;
  final String type; // 'DEBIT' (sale) or 'CREDIT' (payment)
  final double amount;
  final int? saleId; // Optional reference to sale
  final String? description;
  final DateTime createdAt;

  LedgerEntry({
    this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.saleId,
    this.description,
    required this.createdAt,
  });

  /// Create a JSON-serializable map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'type': type,
      'amount': (amount * 100).toInt(),
      'saleId': saleId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a LedgerEntry from database map
  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      type: map['type'] as String,
      amount: ((map['amount'] as num).toDouble()) / 100,
      saleId: map['saleId'] as int?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Copy with modifications
  LedgerEntry copyWith({
    int? id,
    int? customerId,
    String? type,
    double? amount,
    int? saleId,
    String? description,
    DateTime? createdAt,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      saleId: saleId ?? this.saleId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
