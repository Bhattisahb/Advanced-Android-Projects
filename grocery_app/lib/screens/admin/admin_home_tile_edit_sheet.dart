import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/home_screen_tile_model.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/home_screen_tiles_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/services/product_image_storage_service.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

Future<void> showAdminHomeTileEditor(
  BuildContext context,
  HomeScreenTileModel? existing,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => AdminHomeTileEditor(
      key: ValueKey<String>(existing?.id ?? 'new_home_tile'),
      initial: existing,
    ),
  );
}

class _IconChoice {
  const _IconChoice(this.label, this.codePoint);
  final String label;
  final int? codePoint;
}

class AdminHomeTileEditor extends StatefulWidget {
  const AdminHomeTileEditor({super.key, this.initial});

  /// Null → create new tile.
  final HomeScreenTileModel? initial;

  @override
  State<AdminHomeTileEditor> createState() => _AdminHomeTileEditorState();
}

class _AdminHomeTileEditorState extends State<AdminHomeTileEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _sortController;
  late final TextEditingController _categoryController;
  late final TextEditingController _assetController;
  late final TextEditingController _colorHexController;
  late final TextEditingController _imageUrlController;

  HomeTileLinkType _linkType = HomeTileLinkType.categoryFilter;
  int _iconIndex = 0;

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _removeImage = false;
  bool _saving = false;

  /// Product IDs shown first when the shopper taps this shortcut.
  List<String> _productIds = [];

  static final List<_IconChoice> _icons = [
    _IconChoice('Default', null),
    _IconChoice('Star', Icons.star_rate_rounded.codePoint),
    _IconChoice('Restaurant', Icons.restaurant_rounded.codePoint),
    _IconChoice('Percent / deals', Icons.percent_rounded.codePoint),
    _IconChoice('Shopping basket', Icons.shopping_basket_outlined.codePoint),
    _IconChoice('Local offer', Icons.local_offer_outlined.codePoint),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _titleController = TextEditingController(text: e?.title ?? '');
    _sortController = TextEditingController(
      text: e != null ? '${e.sortOrder}' : '0',
    );
    _categoryController =
        TextEditingController(text: e?.categoryFilter ?? '');
    _assetController = TextEditingController(text: e?.assetPath ?? '');
    _colorHexController = TextEditingController(
      text: e != null ? _hexRgb(e.colorArgb) : '53B175',
    );
    _imageUrlController = TextEditingController(text: e?.imageUrl ?? '');
    if (e != null) {
      _linkType = e.linkType;
      final cp = e.iconCodePoint;
      final idx = _icons.indexWhere((c) => c.codePoint == cp);
      _iconIndex = idx >= 0 ? idx : 0;
      _productIds = List<String>.from(e.productIds);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductsProvider>().fetchProducts(includeHiddenFromCatalog: true);
    });
  }

  static String _hexRgb(int argb) {
    final rgb = argb & 0xFFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  Color _parseColorHex() {
    var s = _colorHexController.text.trim().replaceFirst('#', '');
    if (s.length == 6) {
      s = 'FF$s';
    }
    final v = int.tryParse(s, radix: 16);
    if (v == null) return const Color(0xFF53B175);
    return Color(v);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sortController.dispose();
    _categoryController.dispose();
    _assetController.dispose();
    _colorHexController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null) return;
    setState(() {
      _pickedImage = image;
      _removeImage = false;
      _imageUrlController.clear();
    });
  }

  void _stripPicture() {
    setState(() {
      _pickedImage = null;
      _removeImage = true;
      _imageUrlController.clear();
    });
  }

  Future<void> _openPickProducts() async {
    final catalog = context.read<ProductsProvider>().getProducts;
    if (catalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product catalog is empty — refresh products first.'),
        ),
      );
      return;
    }

    final extra = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => HomeShortcutProductPickerSheet(
        catalog: catalog,
        excludeIds: {..._productIds},
      ),
    );

    if (!mounted || extra == null || extra.isEmpty) return;

    setState(() {
      for (final id in extra) {
        if (!_productIds.contains(id)) {
          _productIds.add(id);
        }
      }
    });
  }

  Future<void> _save() async {
    final titleTrim = _titleController.text.trim();
    if (titleTrim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final sortParsed = int.tryParse(_sortController.text.trim());
    if (sortParsed == null || sortParsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sort order must be 0 or higher')),
      );
      return;
    }

    final categoryTrim = _categoryController.text.trim();
    if (_linkType == HomeTileLinkType.categoryFilter &&
        categoryTrim.isEmpty &&
        _productIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a category keyword or add at least one product',
          ),
        ),
      );
      return;
    }

    final color = _parseColorHex();
    final assetTrim = _assetController.text.trim();

    final tilesProv = context.read<HomeScreenTilesProvider>();
    final fs = FirebaseFirestore.instance.collection('home_screen_tiles');

    final base = <String, dynamic>{
      'sortOrder': sortParsed,
      'title': titleTrim,
      'linkType': HomeScreenTileModel.linkTypeToWire(_linkType),
      'colorArgb': color.value,
      'productIds': _productIds,
    };

    if (_linkType != HomeTileLinkType.categoryFilter) {
      base['categoryFilter'] = FieldValue.delete();
    } else {
      base['categoryFilter'] = categoryTrim;
    }

    final iconCp = _icons[_iconIndex].codePoint;

    if (iconCp == null) {
      base['iconCodePoint'] = FieldValue.delete();
    } else {
      base['iconCodePoint'] = iconCp;
    }

    if (assetTrim.isEmpty) {
      base['assetPath'] = FieldValue.delete();
    } else {
      base['assetPath'] = assetTrim;
    }

    setState(() => _saving = true);
    try {
      late final DocumentReference<Map<String, dynamic>> docRef;
      final existingId = widget.initial?.id ?? '';

      if (existingId.isEmpty) {
        docRef = fs.doc();
        await docRef.set(base);
      } else {
        docRef = fs.doc(existingId);
        await docRef.update(base);
      }

      final id = docRef.id;

      if (_pickedImage != null) {
        final url = await const ProductImageStorageService().uploadHomeTileImage(
          tileDocId: id,
          image: _pickedImage!,
        );
        await docRef.update({'imageUrl': url});
      } else if (_removeImage) {
        await docRef.update({'imageUrl': FieldValue.delete()});
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        await docRef.update({'imageUrl': _imageUrlController.text.trim()});
      }

      await tilesProv.fetchTiles();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home tile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview(Color accent) {
    const size = 96.0;
    Widget inner;
    if (_pickedImage != null) {
      inner = Image.file(
        File(_pickedImage!.path),
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    } else if (!_removeImage &&
        widget.initial?.imageUrl != null &&
        widget.initial!.imageUrl!.trim().isNotEmpty) {
      inner = NetworkProductImage(
        imageUrl: widget.initial!.imageUrl!,
        width: size,
        height: size,
        boxFit: BoxFit.cover,
      );
    } else if (_assetController.text.trim().isNotEmpty) {
      inner = Image.asset(
        _assetController.text.trim(),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(
          _icons[_iconIndex].codePoint != null
              ? IconData(_icons[_iconIndex].codePoint!, fontFamily: 'MaterialIcons')
              : Icons.category_rounded,
          color: Colors.white,
          size: 36,
        ),
      );
    } else {
      inner = Icon(
        _icons[_iconIndex].codePoint != null
            ? IconData(_icons[_iconIndex].codePoint!, fontFamily: 'MaterialIcons')
            : Icons.category_rounded,
        color: Colors.white,
        size: 36,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: accent.withValues(alpha: 0.55),
        child: inner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final accent = _parseColorHex();

    return AbsorbPointer(
      absorbing: _saving,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 24 + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initial == null ? 'New home shortcut' : 'Edit home shortcut',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Center(child: _preview(accent)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: (_pickedImage != null ||
                            (!_removeImage &&
                                (widget.initial?.imageUrl?.isNotEmpty ?? false)) ||
                            _imageUrlController.text.trim().isNotEmpty)
                        ? _stripPicture
                        : null,
                    icon: const Icon(Icons.hide_image_outlined, size: 20),
                    label: const Text('Clear image'),
                  ),
                ],
              ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title on home'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<HomeTileLinkType>(
                value: _linkType,
                decoration: const InputDecoration(labelText: 'Opens'),
                items: const [
                  DropdownMenuItem(
                    value: HomeTileLinkType.categoryFilter,
                    child: Text('Category browse'),
                  ),
                  DropdownMenuItem(
                    value: HomeTileLinkType.mostRated,
                    child: Text('Most rated products'),
                  ),
                  DropdownMenuItem(
                    value: HomeTileLinkType.onSale,
                    child: Text('Deals / on sale'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _linkType = v);
                },
              ),
              if (_linkType == HomeTileLinkType.categoryFilter)
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category keyword',
                    helperText: _productIds.isEmpty
                        ? 'Matches product category (e.g. Vegetables)'
                        : 'Optional fallback when product list is cleared',
                  ),
                ),
              TextField(
                controller: _sortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sort order',
                  helperText: 'Lower numbers appear first',
                ),
              ),
              TextField(
                controller: _colorHexController,
                decoration: const InputDecoration(
                  labelText: 'Accent color (hex)',
                  hintText: '53B175 or #53B175',
                ),
                onChanged: (_) => setState(() {}),
              ),
              DropdownButtonFormField<int>(
                value: _iconIndex.clamp(0, _icons.length - 1),
                decoration: const InputDecoration(labelText: 'Icon (no photo)'),
                items: List.generate(
                  _icons.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(_icons[i].label),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => _iconIndex = v);
                },
              ),
              TextField(
                controller: _assetController,
                decoration: const InputDecoration(
                  labelText: 'Bundled asset path (optional)',
                  hintText: 'assets/images/cat/veg.png',
                ),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  helperText: 'Skipped if you upload from gallery above',
                ),
                onChanged: (_) {
                  if (_pickedImage == null) {
                    setState(() => _removeImage = false);
                  }
                },
              ),
              Consumer<ProductsProvider>(
                builder: (context, products, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Products in shortcut',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When you add products, shoppers open that list first when they tap this tile.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_productIds.isEmpty)
                        Text(
                          'None — tile uses “Opens” only.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _productIds.map((id) {
                            final label =
                                products.findProdByIdOrNull(id)?.title ?? id;
                            return InputChip(
                              label: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              onDeleted: () {
                                setState(() => _productIds.remove(id));
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _openPickProducts,
                              icon: const Icon(Icons.add_shopping_cart_outlined),
                              label: const Text('Add products'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _productIds.isEmpty || _saving
                                ? null
                                : () => setState(_productIds.clear),
                            child: const Text('Clear products'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable multi-add picker for home shortcut product IDs.
class HomeShortcutProductPickerSheet extends StatefulWidget {
  const HomeShortcutProductPickerSheet({
    super.key,
    required this.catalog,
    required this.excludeIds,
  });

  final List<ProductModel> catalog;
  final Set<String> excludeIds;

  @override
  State<HomeShortcutProductPickerSheet> createState() =>
      _HomeShortcutProductPickerSheetState();
}

class _HomeShortcutProductPickerSheetState
    extends State<HomeShortcutProductPickerSheet> {
  final TextEditingController _query = TextEditingController();
  final List<String> _staging = [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _titleForProductId(String id) {
    for (final p in widget.catalog) {
      if (p.id == id) return p.title;
    }
    return id;
  }

  List<ProductModel> get _visible {
    final q = _query.text.trim().toLowerCase();
    return widget.catalog.where((p) {
      if (widget.excludeIds.contains(p.id) || _staging.contains(p.id)) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
    }).toList()
      ..sort(
        (a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
  }

  @override
  Widget build(BuildContext context) {
    final padBottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + padBottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Add products',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextField(
              controller: _query,
              decoration: const InputDecoration(
                hintText: 'Search title or product ID',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_staging.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selected (${_staging.length})',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _staging.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final id = _staging[i];
                    return InputChip(
                      label: Text(
                        _titleForProductId(id),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: () {
                        setState(() => _staging.remove(id));
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: _visible.isEmpty
                  ? Center(
                      child: Text(
                        widget.catalog.isEmpty
                            ? 'No products loaded'
                            : 'No matches — try another search',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _visible.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final p = _visible[i];
                        return ListTile(
                          title: Text(p.title),
                          subtitle: Text(p.id),
                          trailing: IconButton(
                            tooltip: 'Add',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                if (!_staging.contains(p.id)) {
                                  _staging.add(p.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _staging.isEmpty
                        ? null
                        : () =>
                            Navigator.pop(context, List<String>.from(_staging)),
                    child: Text(
                      _staging.isEmpty ? 'Add' : 'Add ${_staging.length}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
