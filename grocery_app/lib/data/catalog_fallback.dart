import '../models/products_model.dart';
import 'catalog_product_maps.dart';

/// Offline catalog when Firestore `products` is empty or unreachable.
/// Same rows as [catalogFirestoreMaps] (42 items) — keep in sync with seed data.
List<ProductModel> fallbackGroceryProducts() {
  return catalogFirestoreMaps().map(_rowToProduct).toList();
}

ProductModel _rowToProduct(Map<String, dynamic> m) {
  return ProductModel(
    id: m['id']! as String,
    title: m['title']! as String,
    imageUrl: m['imageUrl']! as String,
    productCategoryName: m['productCategoryName']! as String,
    description: (m['description'] ?? '').toString().trim(),
    price: double.parse(m['price'].toString()),
    salePrice: (m['salePrice'] as num).toDouble(),
    isOnSale: m['isOnSale']! as bool,
    isPiece: m['isPiece']! as bool,
  );
}
