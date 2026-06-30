/// Customer Model
/// Represents both walk-in and registered customers
/// Tracks contact info and customer type

class Customer {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String type; // 'WALK_IN' or 'REGISTERED'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.type = 'WALK_IN',
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a JSON-serializable map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a Customer from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      type: map['type'] as String? ?? 'WALK_IN',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Copy with modifications
  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
