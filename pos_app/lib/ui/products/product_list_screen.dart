/// Product List Screen
/// Premium product management with cards, sorting, filtering, bulk operations
/// Features: Stock badges, category filtering, quick actions, favorites

import 'package:flutter/material.dart';
import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/repositories/product_repository.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productRepository = ProductRepository();
  final _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  
  // Filter and sort options
  String _selectedSort = 'name'; // name, price_asc, price_desc, stock, recent
  Set<int?> _favoriteIds = {};
  Set<int?> _selectedProductIds = {};
  bool _isSelectionMode = false;
  String? _selectedCategory;
  List<String> _categories = [];
  String _viewMode = 'grid'; // grid or list

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterAndSort);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all products and extract unique categories
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productRepository.getAllProducts().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Loading products took too long'),
      );
      
      // Extract unique categories
      final categories = <String>{};
      for (final product in products) {
        categories.add(product.category);
      }
      
      setState(() {
        _products = products;
        _categories = categories.toList()..sort();
        _filterAndSort();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Filter and sort products
  void _filterAndSort() {
    final query = _searchController.text.toLowerCase();
    
    // Filter by search and category
    var filtered = _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == null ||
          p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Apply sorting
    switch (_selectedSort) {
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock':
        filtered.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      default: // name or recent
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() => _filteredProducts = filtered);
  }

  /// Toggle favorite status
  void _toggleFavorite(int? id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  /// Toggle product selection
  void _toggleSelection(int? id) {
    setState(() {
      if (_selectedProductIds.contains(id)) {
        _selectedProductIds.remove(id);
      } else {
        _selectedProductIds.add(id);
      }
    });
  }

  /// Delete product with confirmation
  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _productRepository.deleteProduct(product.id!);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Bulk delete selected products
  Future<void> _bulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: Text('Delete ${_selectedProductIds.length} products? Cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      for (final id in _selectedProductIds) {
        if (id != null) {
          await _productRepository.deleteProduct(id);
        }
      }
      await _loadProducts();
      setState(() => _isSelectionMode = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Products deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        title: const Text('Products', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(_viewMode == 'grid' ? Icons.list : Icons.dashboard),
            onPressed: () {
              setState(() => _viewMode = _viewMode == 'grid' ? 'list' : 'grid');
            },
          ),
          // Selection mode toggle
          if (_products.isNotEmpty)
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) _selectedProductIds.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBubble('${_products.length}', 'Total Products'),
                _buildStatBubble('${_products.where((p) => p.isLowStock).length}', 'Low Stock'),
                _buildStatBubble('${_categories.length}', 'Categories'),
              ],
            ),
          ),

          // Search and filters
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or SKU',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _filterAndSort();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (_) => _filterAndSort(),
                ),
                const SizedBox(height: 8),

                // Category and sort filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category filter
                      FilterChip(
                        label: Text(_selectedCategory ?? 'All Categories'),
                        onSelected: (_) {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Select Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                FilterChip(
                                  label: const Text('All Categories'),
                                  selected: _selectedCategory == null,
                                  onSelected: (_) {
                                    setState(() => _selectedCategory = null);
                                    _filterAndSort();
                                    Navigator.pop(context);
                                  },
                                ),
                                ..._categories.map(
                                  (cat) => FilterChip(
                                    label: Text(cat),
                                    selected: _selectedCategory == cat,
                                    onSelected: (_) {
                                      setState(() => _selectedCategory = cat);
                                      _filterAndSort();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Sort dropdown
                      DropdownButton<String>(
                        value: _selectedSort,
                        items: [
                          const DropdownMenuItem(value: 'name', child: Text('Name')),
                          const DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                          const DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                          const DropdownMenuItem(value: 'stock', child: Text('Stock (Low First)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSort = value);
                            _filterAndSort();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products grid or list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _products.isEmpty ? 'No products yet' : 'No products match your search',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : _viewMode == 'grid'
                        ? GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              final isFavorite = _favoriteIds.contains(product.id);
                              final isSelected = _selectedProductIds.contains(product.id);
                              return _buildProductCard(product, isFavorite, isSelected);
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              final isFavorite = _favoriteIds.contains(product.id);
                              final isSelected = _selectedProductIds.contains(product.id);
                              return _buildProductListItem(product, isFavorite, isSelected);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode && _selectedProductIds.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'bulk_delete',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                  onPressed: _bulkDelete,
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.pushNamed(context, AppConstants.ROUTE_PRODUCT_FORM);
                  },
                ),
              ],
            )
          : FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.ROUTE_PRODUCT_FORM);
              },
            ),
    );
  }

  /// Build stat bubble
  Widget _buildStatBubble(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  /// Build product card (grid view)
  Widget _buildProductCard(Product product, bool isFavorite, bool isSelected) {
    return GestureDetector(
      onTap: _isSelectionMode ? () => _toggleSelection(product.id) : () {
        Navigator.pushNamed(
          context,
          AppConstants.ROUTE_PRODUCT_FORM,
          arguments: product,
        );
      },
      onLongPress: () => _toggleSelection(product.id),
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Colors.blue, width: 2)
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product header with category badge
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isSelectionMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(product.id),
                        ),
                    ],
                  ),
                ),

                // SKU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'SKU: ${product.sku}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),

                const Spacer(),

                // Stock status
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildStockBadge(product),
                ),

                // Price and actions
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PKR ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppConstants.ROUTE_PRODUCT_FORM,
                                  arguments: product,
                                );
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => _toggleFavorite(product.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build product list item
  Widget _buildProductListItem(Product product, bool isFavorite, bool isSelected) {
    return Card(
      elevation: isSelected ? 8 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        side: isSelected
            ? BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(product.id),
              )
            : CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(product.name[0], style: const TextStyle(color: Colors.blue)),
              ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.sku} | Category: ${product.category}'),
            Text('Price: PKR ${product.price.toStringAsFixed(0)} | Stock: ${product.stockQuantity}'),
          ],
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildStockBadgeCompact(product),
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                onPressed: () => _toggleFavorite(product.id),
              ),
            ],
          ),
        ),
        onTap: _isSelectionMode ? () => _toggleSelection(product.id) : () {
          Navigator.pushNamed(
            context,
            AppConstants.ROUTE_PRODUCT_FORM,
            arguments: product,
          );
        },
        onLongPress: () => _toggleSelection(product.id),
      ),
    );
  }

  /// Build stock badge
  Widget _buildStockBadge(Product product) {
    if (product.stockQuantity == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Out of Stock', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
      );
    } else if (product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Low Stock', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('${product.stockQuantity} in stock', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
    );
  }

  /// Build compact stock badge
  Widget _buildStockBadgeCompact(Product product) {
    Color badgeColor;
    String badgeText;

    if (product.stockQuantity == 0) {
      badgeColor = Colors.red;
      badgeText = 'Empty';
    } else if (product.isLowStock) {
      badgeColor = Colors.orange;
      badgeText = 'Low';
    } else {
      badgeColor = Colors.green;
      badgeText = 'OK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(badgeText, style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold)),
    );
  }
}
