import 'package:flutter/material.dart';
import 'package:grocery_app/models/category_catalog_model.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/screens/admin/admin_category_edit_sheet.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:provider/provider.dart';

/// Lists catalog categories and names used on products; rename propagates to all products.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  static const routeName = '/admin-categories';

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _CategoryAdminRow {
  _CategoryAdminRow({
    required this.name,
    required this.productCount,
    this.catalogDoc,
  });

  final String name;
  final int productCount;
  final CategoryCatalogDoc? catalogDoc;
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  late final Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = const AdminService().isCurrentUserAdmin();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future.wait([
        context.read<CategoriesProvider>().fetchCategories(),
        context.read<ProductsProvider>().fetchProducts(includeHiddenFromCatalog: true),
      ]);
    });
  }

  List<_CategoryAdminRow> _buildRows(
    List<CategoryCatalogDoc> catalog,
    List<ProductModel> products,
  ) {
    final counts = <String, int>{};
    for (final p in products) {
      final k = p.productCategoryName;
      counts[k] = (counts[k] ?? 0) + 1;
    }

    final seen = <String>{};
    final rows = <_CategoryAdminRow>[];

    for (final c in catalog) {
      if (c.name.isEmpty) continue;
      seen.add(c.name);
      rows.add(
        _CategoryAdminRow(
          name: c.name,
          productCount: counts[c.name] ?? 0,
          catalogDoc: c,
        ),
      );
    }

    final orphans = counts.keys.where((n) => !seen.contains(n)).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    for (final n in orphans) {
      rows.add(
        _CategoryAdminRow(
          name: n,
          productCount: counts[n] ?? 0,
          catalogDoc: null,
        ),
      );
    }

    return rows;
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<CategoriesProvider>().fetchCategories(),
      context.read<ProductsProvider>().fetchProducts(includeHiddenFromCatalog: true),
    ]);
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              helperText:
                  'Saved to catalog; assign products in product editor',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final name = controller.text.trim();
      if (name.isEmpty) return;

      try {
        await context.read<CategoriesProvider>().createCatalogCategory(name);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$name" added')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _registerOrphan(_CategoryAdminRow row) async {
    try {
      await context.read<CategoriesProvider>().ensureCatalogContains(row.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${row.name}" added to catalog')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _deleteCatalogOnly(CategoryCatalogDoc doc, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove catalog entry?'),
        content: Text(
          'Removes "$name" from the category list only. '
          'Products already using this name are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<CategoriesProvider>().deleteCatalogDoc(doc.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catalog entry removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Widget _categoryLeading(BuildContext context, _CategoryAdminRow row) {
    final scheme = Theme.of(context).colorScheme;
    final url = row.catalogDoc?.imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: NetworkProductImage(
          imageUrl: url,
          width: 52,
          height: 52,
          boxFit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.category_outlined,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Categories')),
            body: const Center(child: Text('You do not have admin access.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Categories'),
            actions: [
              IconButton(
                onPressed: () async => _refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            label: const Text('New category'),
          ),
          body: Consumer2<CategoriesProvider, ProductsProvider>(
            builder: (context, cats, products, _) {
              if (cats.loading && cats.catalog.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final rows = _buildRows(cats.catalog, products.getProducts);
              if (rows.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No categories yet.\nTap New category or add products with a category.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final subtitleParts = <String>[
                    '${row.productCount} product${row.productCount == 1 ? '' : 's'}',
                  ];
                  if (row.catalogDoc != null) {
                    subtitleParts.add('In catalog');
                  } else {
                    subtitleParts.add('Products only — tap ⋮ to add to catalog');
                  }

                  return ListTile(
                    leading: _categoryLeading(context, row),
                    title: Text(row.name),
                    subtitle: Text(subtitleParts.join(' • ')),
                    onTap: () {
                      if (row.catalogDoc != null) {
                        showAdminCategoryEditor(context, row.catalogDoc!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Add this category to the catalog first (⋮ menu) '
                              'to set its picture and edit details.',
                            ),
                          ),
                        );
                      }
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            if (row.catalogDoc != null) {
                              await showAdminCategoryEditor(
                                  context, row.catalogDoc!);
                            }
                            break;
                          case 'register':
                            await _registerOrphan(row);
                            break;
                          case 'remove_catalog':
                            if (row.catalogDoc != null) {
                              await _deleteCatalogOnly(
                                  row.catalogDoc!, row.name);
                            }
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (row.catalogDoc != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit name, order & picture'),
                          ),
                        if (row.catalogDoc == null)
                          const PopupMenuItem(
                            value: 'register',
                            child: Text('Add to catalog'),
                          ),
                        if (row.catalogDoc != null)
                          const PopupMenuItem(
                            value: 'remove_catalog',
                            child: Text('Remove catalog entry'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
