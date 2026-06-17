import 'package:cloud_firestore/cloud_firestore.dart';

/// Row in `categories/{docId}` — optional catalog metadata for store grouping.
class CategoryCatalogDoc {
  CategoryCatalogDoc({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int sortOrder;

  /// HTTPS image URL (e.g. Cloudinary) for shopper category tiles.
  final String? imageUrl;

  factory CategoryCatalogDoc.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawImg = data['imageUrl'] ?? data['image_url'];
    final img = rawImg == null ? '' : rawImg.toString().trim();
    return CategoryCatalogDoc(
      id: doc.id,
      name: (data['name'] ?? '').toString().trim(),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      imageUrl: img.isEmpty ? null : img,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'sortOrder': sortOrder,
        if (imageUrl != null && imageUrl!.trim().isNotEmpty)
          'imageUrl': imageUrl!.trim(),
      };
}
