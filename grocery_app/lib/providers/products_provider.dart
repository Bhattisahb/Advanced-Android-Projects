import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/catalog_fallback.dart';
import '../models/products_model.dart';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> _productsList = [];
  List<ProductModel> get getProducts {
    return _productsList;
  }

  List<ProductModel> get getOnSaleProducts {
    return _productsList.where((element) => element.isOnSale).toList();
  }

  Future<void> fetchProducts({bool includeHiddenFromCatalog = false}) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').get();
      final loaded = <ProductModel>[];

      var skipped = 0;
      for (final doc in snapshot.docs) {
        try {
          final p = ProductModel.fromFirestore(doc);
          if (!includeHiddenFromCatalog && p.hiddenFromCatalog) continue;
          loaded.add(p);
        } catch (e, st) {
          skipped++;
          debugPrint('ProductsProvider: skipped doc ${doc.id}: $e\n$st');
        }
      }

      _productsList = loaded;

      if (kDebugMode && snapshot.docs.isNotEmpty) {
        debugPrint(
          'ProductsProvider: Firestore products docs=${snapshot.docs.length} '
          'loaded=${loaded.length} skipped=$skipped',
        );
      }

      if (_productsList.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'ProductsProvider: no usable product rows — using bundled fallback '
            '(check field types: isOnSale/isPiece as boolean; price as number or string).',
          );
        }
        _productsList = fallbackGroceryProducts();
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'ProductsProvider: Firestore ${e.code} ${e.message} — fallback catalog.',
        );
      }
      _productsList = fallbackGroceryProducts();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
            'ProductsProvider: fetch failed: $e\n$st — fallback catalog.');
      }
      _productsList = fallbackGroceryProducts();
    }
    notifyListeners();
  }

  Future<void> upsertProduct(ProductModel product) async {
    final map = Map<String, dynamic>.from(product.toFirestore());
    if (product.stockQuantity == null) {
      map['stockQuantity'] = FieldValue.delete();
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .set(map, SetOptions(merge: true));

    final index =
        _productsList.indexWhere((element) => element.id == product.id);
    if (index >= 0) {
      _productsList[index] = product;
    } else {
      _productsList.add(product);
    }
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();
    _productsList.removeWhere((element) => element.id == productId);
    notifyListeners();
  }

  ProductModel findProdById(String productId) {
    return _productsList.firstWhere((element) => element.id == productId);
  }

  ProductModel? findProdByIdOrNull(String productId) {
    try {
      return findProdById(productId);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> findByCategory(String categoryName) {
    List<ProductModel> _categoryList = _productsList
        .where((element) => element.productCategoryName
            .toLowerCase()
            .contains(categoryName.toLowerCase()))
        .toList();
    return _categoryList;
  }

  List<ProductModel> searchQuery(String searchText) {
    List<ProductModel> _searchList = _productsList
        .where(
          (element) => element.title.toLowerCase().contains(
                searchText.toLowerCase(),
              ),
        )
        .toList();
    return _searchList;
  }
}
