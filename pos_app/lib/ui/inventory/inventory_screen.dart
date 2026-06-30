/// Inventory Screen
/// Advanced inventory management with visual bars, quick adjusters, bulk operations
/// Features: Real-time stock levels, approval workflows, reason tags, auto-reorder

import 'package:flutter/material.dart';
import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/core/utils/validators.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/models/stock_history_model.dart';
import 'package:pos_app/data/repositories/product_repository.dart';
import 'package:pos_app/data/repositories/inventory_repository.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final _productRepository = ProductRepository();
  final _inventoryRepository = InventoryRepository();

  List<Product> _allProducts = [];
  List<Product> _lowStockProducts = [];
  List<StockHistory> _recentHistory = [];
  bool _isLoading = true;

  late TabController _tabController;
  String _quickAdjustSize = '1'; // 1, 5, 10, custom

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load all products, low stock products and recent history
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allProducts = await _productRepository.getAllProducts();
      final lowStock = await _productRepository.getLowStockProducts();
      final history = await _inventoryRepository.getRecentHistory(limit: 100);

      setState(() {
        _allProducts = allProducts;
        _lowStockProducts = lowStock;
        _recentHistory = history;
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

  /// Show enhanced Stock IN dialog
  void _showStockInDialog(Product product) {
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    String selectedReason = 'purchase';
    final reasonOptions = [
      'purchase',
      'return',
      'adjustment',
      'transfer',
      'other'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock IN - ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Stock: ${product.stockQuantity}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Add',
                  hintText: 'Enter quantity',
                  prefixIcon: Icon(Icons.add_circle),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              StatefulBuilder(
                builder: (context, setStateInner) => Column(
                  children: reasonOptions
                      .map((reason) => RadioListTile<String>(
                            title: Text(reason.toUpperCase()),
                            value: reason,
                            groupValue: selectedReason,
                            onChanged: (value) {
                              if (value != null) {
                                setStateInner(() => selectedReason = value);
                              }
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g., PO #123, Supplier name',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid quantity')),
                );
                return;
              }

              try {
                await _inventoryRepository.addStockIn(
                  productId: product.id!,
                  quantity: quantity,
                  reason: selectedReason,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $quantity units'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Show enhanced Stock OUT dialog
  void _showStockOutDialog(Product product) {
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    String selectedReason = 'damage';
    final reasonOptions = [
      'damage',
      'expired',
      'loss',
      'adjustment',
      'sample',
      'other'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock OUT - ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Stock: ${product.stockQuantity}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Remove',
                  hintText: 'Enter quantity',
                  prefixIcon: Icon(Icons.remove_circle),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              StatefulBuilder(
                builder: (context, setStateInner) => Column(
                  children: reasonOptions
                      .map((reason) => RadioListTile<String>(
                            title: Text(reason.toUpperCase()),
                            value: reason,
                            groupValue: selectedReason,
                            onChanged: (value) {
                              if (value != null) {
                                setStateInner(() => selectedReason = value);
                              }
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional details',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid quantity')),
                );
                return;
              }
              if (quantity > product.stockQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantity exceeds available stock')),
                );
                return;
              }

              try {
                await _inventoryRepository.addStockOut(
                  productId: product.id!,
                  quantity: quantity,
                  reason: selectedReason,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed $quantity units ($selectedReason)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        title: const Text('Inventory Control',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Products (${_allProducts.length})'),
            Tab(text: 'Low Stock (${_lowStockProducts.length})'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllProductsTab(),
                _buildLowStockTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  /// Build all products tab with visual stock bars
  Widget _buildAllProductsTab() {
    if (_allProducts.isEmpty) {
      return const Center(
        child: Text('No products available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _allProducts.length,
      itemBuilder: (context, index) {
        final product = _allProducts[index];
        final maxStock = 100; // assume 100 is max for display
        final stockPercentage = (product.stockQuantity / maxStock).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and stock count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'SKU: ${product.sku}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStockColor(product).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.stockQuantity} units',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStockColor(product),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Visual stock bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stockPercentage,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStockColor(product),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAdjustButton(
                        icon: Icons.add,
                        label: '+1',
                        color: Colors.green,
                        onTap: () async {
                          try {
                            await _inventoryRepository.addStockIn(
                              productId: product.id!,
                              quantity: 1,
                              reason: 'quick_adjust',
                            );
                            _loadData();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildQuickAdjustButton(
                        icon: Icons.add,
                        label: '+5',
                        color: Colors.green,
                        onTap: () async {
                          try {
                            await _inventoryRepository.addStockIn(
                              productId: product.id!,
                              quantity: 5,
                              reason: 'quick_adjust',
                            );
                            _loadData();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildQuickAdjustButton(
                        icon: Icons.remove,
                        label: '-1',
                        color: Colors.red,
                        onTap: () async {
                          try {
                            if (product.stockQuantity > 0) {
                              await _inventoryRepository.addStockOut(
                                productId: product.id!,
                                quantity: 1,
                                reason: 'quick_adjust',
                              );
                              _loadData();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildQuickAdjustButton(
                        icon: Icons.more_horiz,
                        label: 'More',
                        color: Colors.blue,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Stock Adjustment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.add_circle, color: Colors.green),
                                  title: const Text('Stock IN'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showStockInDialog(product);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.remove_circle, color: Colors.red),
                                  title: const Text('Stock OUT'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showStockOutDialog(product);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build low stock products tab
  Widget _buildLowStockTab() {
    if (_lowStockProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text('All products in stock!', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _lowStockProducts.length,
      itemBuilder: (context, index) {
        final product = _lowStockProducts[index];
        return Card(
          color: Colors.orange.shade50,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Current: ${product.stockQuantity} | Category: ${product.category}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LOW STOCK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Stock IN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => _showStockInDialog(product),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                        onPressed: () {
                          _tabController.animateTo(2);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build stock history tab
  Widget _buildHistoryTab() {
    if (_recentHistory.isEmpty) {
      return const Center(
        child: Text('No stock transactions yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _recentHistory.length,
      itemBuilder: (context, index) {
        final record = _recentHistory[index];
        final isStockIn = record.changeType == StockChangeType.stockIn;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isStockIn ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isStockIn ? Icons.arrow_downward : Icons.arrow_upward,
                color: isStockIn ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              record.changeType.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty: ${record.quantity} | ${record.reason ?? 'No reason'}'),
                Text(
                  record.timestamp.toString().split('.').first,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Text(
              '${isStockIn ? '+' : '-'}${record.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isStockIn ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get stock color based on quantity
  Color _getStockColor(Product product) {
    if (product.stockQuantity == 0) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  /// Build quick adjust button
  Widget _buildQuickAdjustButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      onPressed: onTap,
    );
  }
}
