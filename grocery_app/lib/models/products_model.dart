import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ProductModel with ChangeNotifier {
  final String id, title, imageUrl, productCategoryName;
  final String description;
  final double price, salePrice;
  final bool isOnSale, isPiece;

  /// When set, compared to [lowStockThreshold] for admin inventory badges.
  final int? stockQuantity;
  final int lowStockThreshold;

  /// Hidden from shopper catalog when true (still visible in admin product list).
  final bool hiddenFromCatalog;

  ProductModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.productCategoryName,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.isOnSale,
    required this.isPiece,
    this.stockQuantity,
    this.lowStockThreshold = 5,
    this.hiddenFromCatalog = false,
  });

  bool get isLowStock =>
      stockQuantity != null && stockQuantity! <= lowStockThreshold;

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ProductModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  factory ProductModel.fromMap(Map<String, dynamic> data, String fallbackId) {
    final title =
        (data['title'] ?? data['name'] ?? 'Product').toString().trim();
    final category = _category(data);
    final sq = _optionalInt(data['stockQuantity'] ?? data['stock_quantity']);
    final thresh =
        _optionalInt(data['lowStockThreshold'] ?? data['low_stock_threshold']) ??
            5;
    return ProductModel(
      id: data['id']?.toString().trim().isNotEmpty == true
          ? data['id'].toString().trim()
          : fallbackId,
      title: title.isEmpty ? 'Product' : title,
      imageUrl: _imageUrl(data),
      productCategoryName: category,
      description: _description(data, title, category),
      price: _price(data['price']),
      salePrice:
          _price(data['salePrice'] ?? data['sale_price'] ?? data['price']),
      isOnSale: _bool(data['isOnSale'] ?? data['on_sale']),
      isPiece: _bool(data['isPiece'] ?? data['is_piece']),
      stockQuantity: sq,
      lowStockThreshold: thresh < 0 ? 5 : thresh,
      hiddenFromCatalog:
          _bool(data['hiddenFromCatalog'] ?? data['hidden_from_catalog']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'productCategoryName': productCategoryName,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'isOnSale': isOnSale,
      'isPiece': isPiece,
      if (stockQuantity != null) 'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'hiddenFromCatalog': hiddenFromCatalog,
    };
  }
}

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.round();
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

String _description(Map<String, dynamic> data, String title, String category) {
  for (final key in [
    'description',
    'shortDescription',
    'details',
    'about',
    'body',
  ]) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return 'Fresh $category — $title. Quality-checked for your kitchen and delivered with care.';
}

double _price(dynamic value) {
  try {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final s = value.toString().trim();
    if (s.isEmpty) return 0;
    return double.parse(s);
  } catch (_) {
    return 0;
  }
}

bool _bool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

String _category(Map<String, dynamic> data) {
  for (final key in [
    'productCategoryName',
    'category',
    'productCategory',
    'product_category',
  ]) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return 'Groceries';
}

String _imageUrl(Map<String, dynamic> data) {
  for (final key in ['imageUrl', 'image_url', 'img', 'photoUrl']) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return '';
}
