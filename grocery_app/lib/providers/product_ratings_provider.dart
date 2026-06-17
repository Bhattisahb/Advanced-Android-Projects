import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/products_model.dart';

/// Loads `product_reviews` and ranks products by average star rating (tie-break: more reviews).
class ProductRatingsProvider with ChangeNotifier {
  Map<String, double> _averageByProductId = {};
  Map<String, int> _countByProductId = {};
  List<String> _rankedProductIds = [];

  Object? lastError;

  Map<String, double> get averageByProductId =>
      Map.unmodifiable(_averageByProductId);

  double? averageFor(String productId) => _averageByProductId[productId];

  int reviewCountFor(String productId) => _countByProductId[productId] ?? 0;

  /// Product IDs ordered by highest average rating first.
  List<String> get rankedProductIds => List.unmodifiable(_rankedProductIds);

  Future<void> refresh() async {
    lastError = null;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('product_reviews').get();

      final sums = <String, double>{};
      final counts = <String, int>{};

      for (final doc in snap.docs) {
        final d = doc.data();
        final pid = d['productId']?.toString();
        if (pid == null || pid.isEmpty) continue;

        final raw = d['rating'];
        double? value;
        if (raw is int) {
          value = raw.toDouble();
        } else if (raw is double) {
          value = raw;
        } else {
          continue;
        }

        sums[pid] = (sums[pid] ?? 0) + value;
        counts[pid] = (counts[pid] ?? 0) + 1;
      }

      final avgs = <String, double>{};
      for (final e in counts.entries) {
        avgs[e.key] = sums[e.key]! / e.value;
      }

      final ranked = avgs.entries.toList()
        ..sort((a, b) {
          final byAvg = b.value.compareTo(a.value);
          if (byAvg != 0) return byAvg;
          return counts[b.key]!.compareTo(counts[a.key]!);
        });

      _averageByProductId = avgs;
      _countByProductId = counts;
      _rankedProductIds = ranked.map((e) => e.key).toList();
    } catch (e, st) {
      lastError = e;
      if (kDebugMode) {
        debugPrint('ProductRatingsProvider.refresh failed: $e\n$st');
      }
      _averageByProductId = {};
      _countByProductId = {};
      _rankedProductIds = [];
    }
    notifyListeners();
  }

  /// Maps ranked IDs to catalog products (skips unknown IDs).
  List<ProductModel> productsInRatingOrder(
    List<ProductModel> catalog, {
    int minReviews = 1,
    int limit = 500,
  }) {
    ProductModel? find(String id) {
      try {
        return catalog.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }

    final out = <ProductModel>[];
    for (final id in _rankedProductIds) {
      if ((_countByProductId[id] ?? 0) < minReviews) continue;
      final p = find(id);
      if (p != null) {
        out.add(p);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}
