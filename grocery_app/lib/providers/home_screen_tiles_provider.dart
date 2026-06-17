import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grocery_app/consts/home_screen_tile_presets.dart';
import 'package:grocery_app/models/home_screen_tile_model.dart';

/// Loads shopper home shortcut bubbles from Firestore (`home_screen_tiles`).
class HomeScreenTilesProvider with ChangeNotifier {
  HomeScreenTilesProvider();

  static const _collection = 'home_screen_tiles';

  List<HomeScreenTileModel> _remote = [];
  bool loading = false;

  /// Raw docs from Firestore (possibly empty).
  List<HomeScreenTileModel> get remoteTiles =>
      List<HomeScreenTileModel>.unmodifiable(_remote);

  /// Tiles shown on the customer home grid.
  List<HomeScreenTileModel> get shopperTiles {
    if (_remote.isEmpty) return HomeScreenTilePresets.models();
    final copy = List<HomeScreenTileModel>.from(_remote)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  Future<void> fetchTiles() async {
    loading = true;
    notifyListeners();
    try {
      final snap =
          await FirebaseFirestore.instance.collection(_collection).get();
      _remote =
          snap.docs.map((d) => HomeScreenTileModel.fromFirestore(d)).toList();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeScreenTilesProvider.fetchTiles failed: $e\n$st');
      }
      _remote = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Writes the bundled preset grid once (admin).
  Future<void> seedPresetTiles() async {
    if (_remote.isNotEmpty) {
      throw StateError('Home tiles already exist. Delete them first if you want to re-seed.');
    }
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection(_collection);
    for (final p in HomeScreenTilePresets.models()) {
      final ref = col.doc();
      batch.set(ref, p.toFirestore());
    }
    await batch.commit();
    await fetchTiles();
  }

  Future<void> deleteTile(String docId) async {
    await FirebaseFirestore.instance.collection(_collection).doc(docId).delete();
    await fetchTiles();
  }

  Future<void> applyReorder(List<String> orderedDocIds) async {
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection(_collection);
    for (var i = 0; i < orderedDocIds.length; i++) {
      batch.update(col.doc(orderedDocIds[i]), {'sortOrder': i});
    }
    await batch.commit();
    await fetchTiles();
  }
}
