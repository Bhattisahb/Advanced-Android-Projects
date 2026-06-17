import 'package:flutter/material.dart';
import 'package:grocery_app/models/home_screen_tile_model.dart';
import 'package:grocery_app/providers/home_screen_tiles_provider.dart';
import 'package:grocery_app/screens/admin/admin_home_tile_edit_sheet.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:provider/provider.dart';

/// Configure shopper home category shortcuts (`home_screen_tiles`).
class AdminHomeTilesScreen extends StatefulWidget {
  const AdminHomeTilesScreen({super.key});

  static const routeName = '/admin-home-tiles';

  @override
  State<AdminHomeTilesScreen> createState() => _AdminHomeTilesScreenState();
}

class _AdminHomeTilesScreenState extends State<AdminHomeTilesScreen> {
  late final Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = const AdminService().isCurrentUserAdmin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeScreenTilesProvider>().fetchTiles();
    });
  }

  Future<void> _refresh() =>
      context.read<HomeScreenTilesProvider>().fetchTiles();

  /// Re-fetch tiles before editing so pinned [productIds] match Firestore and are not wiped on save.
  Future<void> _openTileEditor(HomeScreenTileModel tile) async {
    final tilesProv = context.read<HomeScreenTilesProvider>();
    await tilesProv.fetchTiles();
    if (!mounted) return;
    var latest = tile;
    for (final x in tilesProv.remoteTiles) {
      if (x.id == tile.id) {
        latest = x;
        break;
      }
    }
    await showAdminHomeTileEditor(context, latest);
  }

  String _linkSubtitle(HomeScreenTileModel t) {
    final n = t.productIds.length;
    final pin = n == 0
        ? ''
        : ' • $n product${n == 1 ? '' : 's'} pinned';
    switch (t.linkType) {
      case HomeTileLinkType.mostRated:
        return 'Most rated • sort ${t.sortOrder}$pin';
      case HomeTileLinkType.onSale:
        return 'Deals / on sale • sort ${t.sortOrder}$pin';
      case HomeTileLinkType.categoryFilter:
        return 'Category: ${t.categoryFilter ?? "?"} • sort ${t.sortOrder}$pin';
    }
  }

  Future<void> _confirmDelete(HomeScreenTileModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete shortcut?'),
        content: Text('Remove "${t.title}" from the home grid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<HomeScreenTilesProvider>().deleteTile(t.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${t.title}" removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _seedPresets() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load default home shortcuts?'),
        content: const Text(
          'Creates the classic grocery grid in Firestore. '
          'Use this once on an empty list; you can edit tiles afterward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create defaults'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await context.read<HomeScreenTilesProvider>().seedPresetTiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default shortcuts created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Widget _leadingThumb(HomeScreenTileModel t) {
    final url = t.imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: NetworkProductImage(
          imageUrl: url,
          width: 48,
          height: 48,
          boxFit: BoxFit.cover,
        ),
      );
    }
    final asset = t.assetPath?.trim();
    if (asset != null && asset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(t.materialIcon),
          ),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: t.accentColor.withValues(alpha: 0.35),
      child: Icon(t.materialIcon, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home shortcuts')),
            body: const Center(child: Text('You do not have admin access.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home shortcuts'),
            actions: [
              IconButton(onPressed: () async => _refresh(), icon: const Icon(Icons.refresh)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAdminHomeTileEditor(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add shortcut'),
          ),
          body: Consumer<HomeScreenTilesProvider>(
            builder: (context, homeTiles, _) {
              if (homeTiles.loading && homeTiles.remoteTiles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final tiles = List<HomeScreenTileModel>.from(homeTiles.remoteTiles)
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

              if (tiles.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No shortcuts in Firestore yet.\n'
                          'Shoppers see bundled defaults until you publish tiles here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _seedPresets,
                          icon: const Icon(Icons.download_done_rounded),
                          label: const Text('Create default grid'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => showAdminHomeTileEditor(context, null),
                          icon: const Icon(Icons.add),
                          label: const Text('Add custom shortcut'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Drag the handle to reorder. Tap a row to edit.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: tiles.length,
                      onReorder: (oldIndex, newIndex) async {
                        var ni = newIndex;
                        if (ni > oldIndex) ni -= 1;
                        final reordered = List<HomeScreenTileModel>.from(tiles);
                        final moved = reordered.removeAt(oldIndex);
                        reordered.insert(ni, moved);
                        await context.read<HomeScreenTilesProvider>().applyReorder(
                              reordered.map((e) => e.id).toList(),
                            );
                      },
                      itemBuilder: (context, index) {
                        final t = tiles[index];
                        return Card(
                          key: ValueKey(t.id),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: _leadingThumb(t),
                            ),
                            title: Text(t.title),
                            subtitle: Text(_linkSubtitle(t)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(t),
                            ),
                            onTap: () => _openTileEditor(t),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
