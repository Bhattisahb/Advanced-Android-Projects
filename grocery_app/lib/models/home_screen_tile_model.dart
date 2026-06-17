import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum HomeTileLinkType {
  categoryFilter,
  mostRated,
  onSale,
}

/// Configures one shortcut bubble on the shopper home grid.
class HomeScreenTileModel {
  HomeScreenTileModel({
    required this.id,
    required this.sortOrder,
    required this.title,
    required this.linkType,
    this.categoryFilter,
    required this.colorArgb,
    this.iconCodePoint,
    this.assetPath,
    this.imageUrl,
    this.productIds = const [],
  });

  /// Empty when this row is a bundled preset (not from Firestore).
  final String id;
  final int sortOrder;
  final String title;
  final HomeTileLinkType linkType;

  /// Used when [linkType] is [HomeTileLinkType.categoryFilter] ([CategoryScreen] argument).
  final String? categoryFilter;
  final int colorArgb;
  final int? iconCodePoint;
  final String? assetPath;
  final String? imageUrl;

  /// When non-empty, tapping the home bubble opens this curated list first.
  final List<String> productIds;

  Color get accentColor => Color(colorArgb);

  IconData get materialIcon {
    final cp = iconCodePoint;
    if (cp == null) return Icons.category_rounded;
    return IconData(cp, fontFamily: 'MaterialIcons');
  }

  static HomeTileLinkType _parseLinkType(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'most_rated':
      case 'mostrated':
        return HomeTileLinkType.mostRated;
      case 'on_sale':
      case 'onsale':
      case 'combo':
        return HomeTileLinkType.onSale;
      case 'category_filter':
      case 'category':
      default:
        return HomeTileLinkType.categoryFilter;
    }
  }

  static String linkTypeToWire(HomeTileLinkType t) {
    switch (t) {
      case HomeTileLinkType.categoryFilter:
        return 'category_filter';
      case HomeTileLinkType.mostRated:
        return 'most_rated';
      case HomeTileLinkType.onSale:
        return 'on_sale';
    }
  }

  factory HomeScreenTileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final linkType = _parseLinkType(data['linkType']?.toString());
    final cfRaw = data['categoryFilter'] ?? data['category_filter'];
    final cf = cfRaw == null ? '' : cfRaw.toString().trim();

    final iconRaw = data['iconCodePoint'] ?? data['icon_code_point'];
    final int? iconCp =
        iconRaw == null ? null : (iconRaw is num ? iconRaw.toInt() : int.tryParse('$iconRaw'));

    final assetRaw = data['assetPath'] ?? data['asset_path'];
    final asset =
        assetRaw == null ? null : assetRaw.toString().trim().isEmpty ? null : assetRaw.toString().trim();

    final imgRaw = data['imageUrl'] ?? data['image_url'];
    final img =
        imgRaw == null ? null : imgRaw.toString().trim().isEmpty ? null : imgRaw.toString().trim();

    final colorRaw = data['colorArgb'] ?? data['color_argb'];
    final colorArgb = colorRaw is num ? colorRaw.toInt() : int.tryParse('$colorRaw') ?? 0xFF53B175;

    final sortRaw = data['sortOrder'] ?? data['sort_order'];
    final sortOrder = sortRaw is num ? sortRaw.toInt() : int.tryParse('$sortRaw') ?? 0;

    final idsRaw = data['productIds'] ?? data['product_ids'];
    final productIds = _parseProductIds(idsRaw);

    return HomeScreenTileModel(
      id: doc.id,
      sortOrder: sortOrder,
      title: (data['title'] ?? '').toString().trim(),
      linkType: linkType,
      categoryFilter: cf.isEmpty ? null : cf,
      colorArgb: colorArgb,
      iconCodePoint: iconCp,
      assetPath: asset,
      imageUrl: img,
      productIds: productIds,
    );
  }

  static List<String> _parseProductIds(dynamic raw) {
    if (raw == null) return [];

    // JSON/Firestore console imports occasionally store arrays as maps like {"0":"id1"}.
    if (raw is Map) {
      final entries = raw.entries.toList()
        ..sort((a, b) {
          final ka = num.tryParse(a.key.toString());
          final kb = num.tryParse(b.key.toString());
          if (ka != null && kb != null) return ka.compareTo(kb);
          return a.key.toString().compareTo(b.key.toString());
        });
      return entries
          .map((e) => e.value)
          .map((v) => v.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return [];
      if (s.contains(',')) {
        return s
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [s];
    }

    if (raw is Iterable) {
      return raw
          .map((dynamic e) {
            if (e is String) return e.trim();
            if (e is Map) {
              final id = e['id'] ?? e['productId'] ?? e['product_id'];
              if (id != null) return id.toString().trim();
            }
            return e.toString().trim();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final s = raw.toString().trim();
    return s.isEmpty ? [] : [s];
  }

  Map<String, dynamic> toFirestore() => {
        'sortOrder': sortOrder,
        'title': title,
        'linkType': linkTypeToWire(linkType),
        if (categoryFilter != null && categoryFilter!.trim().isNotEmpty)
          'categoryFilter': categoryFilter!.trim(),
        'colorArgb': colorArgb,
        if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
        if (assetPath != null && assetPath!.trim().isNotEmpty) 'assetPath': assetPath!.trim(),
        if (imageUrl != null && imageUrl!.trim().isNotEmpty) 'imageUrl': imageUrl!.trim(),
        'productIds': productIds,
      };
}
