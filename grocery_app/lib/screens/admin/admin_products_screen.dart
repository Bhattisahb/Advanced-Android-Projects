import 'package:flutter/material.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/screens/admin/admin_product_edit_screen.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:provider/provider.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  static const routeName = '/admin-products';

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late final Future<bool> _isAdminFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isAdminFuture = const AdminService().isCurrentUserAdmin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().fetchProducts(includeHiddenFromCatalog: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('This will remove "${product.title}" from Firestore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await context.read<ProductsProvider>().deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.title} deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  void _openEditor([String? productId]) {
    Navigator.pushNamed(
      context,
      AdminProductEditScreen.routeName,
      arguments: productId,
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
            appBar: AppBar(title: const Text('Admin products')),
            body: const Center(
              child: Text('You do not have admin access.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin products'),
            actions: [
              IconButton(
                onPressed: () =>
                    context.read<ProductsProvider>().fetchProducts(includeHiddenFromCatalog: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search title, ID, or category',
                    prefixIcon: const Icon(Icons.search, size: 22),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Add product'),
          ),
          body: Consumer<ProductsProvider>(
            builder: (context, productsProvider, _) {
              final products = productsProvider.getProducts;
              if (products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final q = _searchController.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? products
                  : products.where((p) {
                      return p.title.toLowerCase().contains(q) ||
                          p.id.toLowerCase().contains(q) ||
                          p.productCategoryName.toLowerCase().contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      q.isEmpty
                          ? 'No products.'
                          : 'No matches for "$q".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkProductImage(
                        imageUrl: product.imageUrl,
                        width: 56,
                        height: 56,
                        boxFit: BoxFit.cover,
                      ),
                    ),
                    title: Text(product.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.productCategoryName} • ${formatPkr(product.price)}',
                        ),
                        if (product.stockQuantity != null ||
                            product.hiddenFromCatalog ||
                            product.isLowStock)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (product.hiddenFromCatalog)
                                  Chip(
                                    label: const Text('Hidden'),
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: const TextStyle(fontSize: 11),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (product.stockQuantity != null)
                                  Chip(
                                    label: Text(
                                      'Stock ${product.stockQuantity}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (product.isLowStock)
                                  Chip(
                                    label: const Text('Low stock'),
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: const TextStyle(fontSize: 11),
                                    backgroundColor:
                                        Colors.orange.shade100,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: product.stockQuantity != null ||
                        product.hiddenFromCatalog ||
                        product.isLowStock,
                    onTap: () => _openEditor(product.id),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteProduct(product),
                      icon: const Icon(Icons.delete_outline),
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
