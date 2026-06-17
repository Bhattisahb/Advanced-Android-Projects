import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grocery_app/models/category_catalog_model.dart';
import 'package:grocery_app/models/products_model.dart';

class CategoriesProvider with ChangeNotifier {
  List<CategoryCatalogDoc> _catalog = [];
  bool loading = false;

  List<CategoryCatalogDoc> get catalog => List.unmodifiable(_catalog);

  /// Names from catalog + every distinct [ProductModel.productCategoryName].
  List<String> mergedNames(List<ProductModel> products) {
    final set = <String>{};
    for (final c in _catalog) {
      if (c.name.isNotEmpty) set.add(c.name);
    }
    for (final p in products) {
      if (p.productCategoryName.isNotEmpty) set.add(p.productCategoryName);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<void> fetchCategories() async {
    loading = true;
    notifyListeners();
    try {
      final snap =
          await FirebaseFirestore.instance.collection('categories').get();
      final loaded =
          snap.docs.map(CategoryCatalogDoc.fromFirestore).toList()
            ..sort((a, b) {
              final c = a.sortOrder.compareTo(b.sortOrder);
              if (c != 0) return c;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
      _catalog = loaded;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('CategoriesProvider.fetchCategories failed: $e\n$st');
      }
      _catalog = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createCatalogCategory(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;

    final exists = _catalog.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      throw StateError('A category named "$name" already exists in the catalog.');
    }

    final maxOrder = _catalog.isEmpty
        ? -1
        : _catalog.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);

    await FirebaseFirestore.instance.collection('categories').add({
      'name': name,
      'sortOrder': maxOrder + 1,
    });
    await fetchCategories();
  }

  /// Persists name (optional rename across products), sort order, and image URL.
  Future<void> saveCatalogCategoryEdits({
    required CategoryCatalogDoc doc,
    required String newName,
    required int sortOrder,
    String? newImageUrl,
    bool removeImage = false,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is required');
    }
    if (sortOrder < 0) {
      throw ArgumentError('Sort order must be zero or positive');
    }

    if (doc.name != trimmed) {
      await renameCategoryEverywhere(oldName: doc.name, newName: trimmed);
    }

    final ref = FirebaseFirestore.instance.collection('categories').doc(doc.id);
    final patch = <String, dynamic>{'sortOrder': sortOrder};
    if (removeImage) {
      patch['imageUrl'] = FieldValue.delete();
    } else if (newImageUrl != null && newImageUrl.trim().isNotEmpty) {
      patch['imageUrl'] = newImageUrl.trim();
    }
    await ref.update(patch);
    await fetchCategories();
  }

  /// Updates every product with [oldName] to [newName], then catalog rows whose `name` was [oldName].
  Future<void> renameCategoryEverywhere({
    required String oldName,
    required String newName,
  }) async {
    final oldT = oldName.trim();
    final newT = newName.trim();
    if (oldT.isEmpty || newT.isEmpty || oldT == newT) return;

    final duplicateCatalogName = _catalog.any(
      (c) =>
          c.name.toLowerCase() == newT.toLowerCase() &&
          c.name.toLowerCase() != oldT.toLowerCase(),
    );
    if (duplicateCatalogName) {
      throw StateError(
        'A catalog category named "$newT" already exists. '
        'Rename or merge it before reusing this name.',
      );
    }

    await _batchRenameProductsCategory(oldT, newT);

    final catSnap = await FirebaseFirestore.instance
        .collection('categories')
        .where('name', isEqualTo: oldT)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in catSnap.docs) {
      batch.update(d.reference, {'name': newT});
    }
    await batch.commit();

    await fetchCategories();
  }

  Future<void> deleteCatalogDoc(String docId) async {
    await FirebaseFirestore.instance.collection('categories').doc(docId).delete();
    await fetchCategories();
  }

  Future<void> _batchRenameProductsCategory(String oldName, String newName) async {
    while (true) {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('productCategoryName', isEqualTo: oldName)
          .limit(450)
          .get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.update(d.reference, {'productCategoryName': newName});
      }
      await batch.commit();
    }
  }

  /// Registers [name] in catalog if missing (used from admin categories UI).
  Future<void> ensureCatalogContains(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;
    final exists = _catalog.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) return;
    await createCatalogCategory(name);
  }
}
