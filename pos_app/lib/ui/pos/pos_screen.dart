/// POS/Billing Screen
/// Minimal UI for point-of-sale operations
/// - Product grid/list
/// - Shopping cart
/// - Discount & tax inputs
/// - Checkout button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/models/cart_item_model.dart';
import 'package:pos_app/data/models/customer_model.dart';
import 'package:pos_app/data/repositories/product_repository.dart';
import 'package:pos_app/data/repositories/pos_repository.dart';
import 'package:pos_app/data/local/customer_dao.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({Key? key}) : super(key: key);

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _searchController = TextEditingController();
  final _customerSearchController = TextEditingController();
  int? _selectedCustomerId;
  String _paymentMethod = 'CASH';
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'ALL';

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    _searchController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  /// Handle checkout
  Future<void> _handleCheckout() async {
    final pos = context.read<POSRepository>();

    if (pos.cart.isEmpty) {
      _showError('Cart is empty');
      return;
    }

    // Validate inputs
    final discountText = _discountController.text.trim();
    final taxText = _taxController.text.trim();

    final discountPercent = double.tryParse(discountText);
    final taxPercent = double.tryParse(taxText);

    if (discountPercent == null || discountPercent < 0 || discountPercent > 100) {
      _showError('Discount must be a number between 0-100');
      return;
    }

    if (taxPercent == null || taxPercent < 0 || taxPercent > 100) {
      _showError('Tax must be a number between 0-100');
      return;
    }

    if (_paymentMethod == 'CREDIT' && _selectedCustomerId == null) {
      _showError('Please select a customer for CREDIT payment');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final saleId = await pos.checkout(
        customerId: _selectedCustomerId,
        discountPercentage: discountPercent,
        taxPercentage: taxPercent,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        _showSuccess('Sale completed! ID: $saleId');
        _resetForm();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetForm() {
    _discountController.text = '0';
    _taxController.text = '0';
    _selectedCustomerId = null;
    _paymentMethod = 'CASH';
  }

  /// Show checkout preview dialog
  void _showCheckoutPreview() {
    final pos = context.read<POSRepository>();
    final discountPercent = double.tryParse(_discountController.text) ?? 0;
    final taxPercent = double.tryParse(_taxController.text) ?? 0;
    final subtotalAmount = pos.subtotal;
    final discountAmount = pos.calculateDiscountAmount(discountPercent);
    final amountAfterDiscount = subtotalAmount - discountAmount;
    final taxAmount = amountAfterDiscount * (taxPercent / 100);
    final totalAmount = amountAfterDiscount + taxAmount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Checkout Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _receiptRow('Items:', pos.cart.length.toString()),
              _receiptRow('Subtotal:', 'PKR ${subtotalAmount.toStringAsFixed(2)}'),
              if (discountPercent > 0)
                _receiptRow('Discount (${discountPercent.toStringAsFixed(1)}%):', '-PKR ${discountAmount.toStringAsFixed(2)}', Colors.red),
              if (taxPercent > 0)
                _receiptRow('Tax (${taxPercent.toStringAsFixed(1)}%):', '+PKR ${taxAmount.toStringAsFixed(2)}', Colors.orange),
              const Divider(height: 16),
              _receiptRow(
                'TOTAL:',
                'PKR ${totalAmount.toStringAsFixed(2)}',
                Colors.blue,
                true,
                16,
              ),
              const SizedBox(height: 12),
              _receiptRow('Payment:', _paymentMethod, _getPaymentColor(_paymentMethod)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCheckout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm & Pay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Build receipt row
  Widget _receiptRow(String label, String value, [Color? valueColor, bool isBold = false, double fontSize = 12]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Get payment method color
  Color _getPaymentColor(String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'CARD':
        return Colors.blue;
      case 'CREDIT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - Billing'),
        centerTitle: true,
        elevation: 2,
        actions: [
          Consumer<POSRepository>(
            builder: (context, pos, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Badge(
                  label: Text(pos.cart.length.toString()),
                  child: const Icon(Icons.shopping_cart),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      resizeToAvoidBottomInset: true,
      body: isLandscape
          ? _buildLandscapeLayout()
          : _buildPortraitLayout(),
    );
  }

  /// Build navigation drawer with quick access features
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.point_of_sale, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'POS System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Quick stats
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Consumer<POSRepository>(
                  builder: (context, pos, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Items', pos.cart.length.toString(), Colors.blue),
                      _buildStatCard('Total', 'PKR ${pos.subtotal.toStringAsFixed(0)}', Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.blue),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to inventory management
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.green),
            title: const Text('Customers'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to customer management
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.orange),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to reports
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: const Text('Recent Sales'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to recent sales
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_sync, color: Colors.indigo),
            title: const Text('Sync Data'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing data...')),
              );
              // TODO: Implement sync functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.clear_all, color: Colors.red),
            title: const Text('Clear Cache'),
            onTap: () {
              Navigator.pop(context);
              _showClearCacheDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.grey),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  /// Build stat card for drawer
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Show clear cache confirmation dialog
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleClearCache();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Handle clear cache
  void _handleClearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement actual cache clearing
  }

  /// Show about dialog
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'POS System',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 All rights reserved',
      children: [
        const Text(
          'A complete Point of Sale system with inventory management, customer tracking, and sales reporting.',
        ),
      ],
    );
  }

  /// Landscape layout: side-by-side products and cart
  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      child: Row(
        children: [
          // Products panel
          Expanded(
            flex: 2,
            child: _buildProductsPanel(),
          ),
          // Divider
          const VerticalDivider(width: 1),
          // Cart panel
          Expanded(
            flex: 1,
            child: _buildCartPanel(),
          ),
        ],
      ),
    );
  }

  /// Portrait layout: stacked products and cart
  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Products panel
          _buildProductsPanel(),
          // Divider
          const Divider(height: 1),
          // Cart panel
          _buildCartPanel(),
        ],
      ),
    );
  }

  /// Build products list/grid
  Widget _buildProductsPanel() {
    return FutureBuilder<List<Product>>(
      future: context.read<ProductRepository>().getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text('No products available'),
          );
        }

        // Filter products based on search
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          products = products
              .where((p) =>
                  p.name.toLowerCase().contains(searchQuery) ||
                  p.sku.toLowerCase().contains(searchQuery))
              .toList();
        }

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final crossAxisCount = isLandscape ? 4 : 3;

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (_) => setState(() {}),
              ),
            ),
            // Products grid
            products.isEmpty
                ? Center(
                    child: Text(
                      'No products found for "${_searchController.text}"',
                      textAlign: TextAlign.center,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(6),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(product);
                    },
                  ),
          ],
        );
      },
    );
  }

  /// Build individual product card
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        final pos = context.read<POSRepository>();
        final cartItem = CartItem(
          productId: product.id!,
          productName: product.name,
          productSku: product.sku,
          basePrice: product.price,
        );
        pos.addToCart(cartItem);
        setState(() {});
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'SKU: ${product.sku}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Stock: ${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: 9,
                            color: product.stockQuantity < 5
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      'PKR ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton('+1', () {
                        final pos = context.read<POSRepository>();
                        final cartItem = CartItem(
                          productId: product.id!,
                          productName: product.name,
                          productSku: product.sku,
                          basePrice: product.price,
                        );
                        pos.addToCart(cartItem);
                        setState(() {});
                      }),
                      _buildQuickButton('+5', () {
                        final pos = context.read<POSRepository>();
                        for (int i = 0; i < 5; i++) {
                          final cartItem = CartItem(
                            productId: product.id!,
                            productName: product.name,
                            productSku: product.sku,
                            basePrice: product.price,
                          );
                          pos.addToCart(cartItem);
                        }
                        setState(() {});
                      }),
                    ],
                  ),
                ],
              ),
            ),
            // Stock badge
            if (product.stockQuantity < 5)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Low Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build quick add button
  Widget _buildQuickButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 34,
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 8, color: Colors.white),
        ),
      ),
    );
  }

  /// Build cart panel
  Widget _buildCartPanel() {
    return Consumer<POSRepository>(
      builder: (context, pos, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cart items - non-scrollable list
            pos.cart.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Cart is Empty',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add items from the product list',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: pos.cart.length,
                    itemBuilder: (context, index) {
                      final item = pos.cart[index];
                      return _buildCartItem(item, pos);
                    },
                  ),
            // Divider between cart items and checkout
            if (pos.cart.isNotEmpty) const Divider(height: 1),
            // Cart summary and checkout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Selection
                  _buildCustomerSelector(),
                  const SizedBox(height: 8),
                  // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 11)),
                          Text(
                            'PKR ${pos.subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Discount input
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _discountController,
                          decoration: InputDecoration(
                            labelText: 'Discount %',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixText: '%',
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tax input
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _taxController,
                          decoration: InputDecoration(
                            labelText: 'Tax %',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixText: '%',
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Payment method
                      SizedBox(
                        height: 42,
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          items: ['CASH', 'CARD', 'CREDIT']
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: e == 'CASH'
                                              ? Colors.green
                                              : e == 'CARD'
                                                  ? Colors.blue
                                                  : Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(e, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _paymentMethod = value);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Payment',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Totals
                      _buildTotalRow('Discount', pos, fontSize: 10),
                      _buildTotalRow('Tax', pos, fontSize: 10),
                      const Divider(height: 12),
                      // Total amount - prominent display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Consumer<POSRepository>(
                              builder: (context, pos, _) {
                                final discountPercent = double.tryParse(_discountController.text) ?? 0;
                                final taxPercent = double.tryParse(_taxController.text) ?? 0;
                                final subtotalAmount = pos.subtotal;
                                final discountAmount = pos.calculateDiscountAmount(discountPercent);
                                final amountAfterDiscount = subtotalAmount - discountAmount;
                                final taxAmount = amountAfterDiscount * (taxPercent / 100);
                                final totalAmount = amountAfterDiscount + taxAmount;
                                return Text(
                                  'PKR ${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.blue,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Checkout button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _showCheckoutPreview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.all(0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Checkout',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Clear cart button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            pos.clearCart();
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Clear Cart', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        );
      },
    );
  }

  /// Build individual cart item
  Widget _buildCartItem(CartItem item, POSRepository pos) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[100]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        Text(
                          item.productSku,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 8, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        pos.removeFromCart(item.productId);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            icon: const Icon(Icons.remove, size: 12),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (item.quantity > 1) {
                                pos.updateQuantity(
                                  item.productId,
                                  item.quantity - 1,
                                );
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            item.quantity.toString(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            icon: const Icon(Icons.add, size: 12),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              pos.updateQuantity(
                                item.productId,
                                item.quantity + 1,
                              );
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PKR ${item.lineTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build total row
  Widget _buildTotalRow(String label, POSRepository pos, {bool isBold = false, double fontSize = 12}) {
    final discountPercent = double.tryParse(_discountController.text) ?? 0;
    final taxPercent = double.tryParse(_taxController.text) ?? 0;

    final subtotalAmount = pos.subtotal;
    final discountAmount = pos.calculateDiscountAmount(discountPercent);
    final amountAfterDiscount = subtotalAmount - discountAmount;
    final taxAmount = amountAfterDiscount * (taxPercent / 100);
    final totalAmount = amountAfterDiscount + taxAmount;

    double amount = 0;
    if (label == 'Discount') {
      amount = discountAmount;
    } else if (label == 'Tax') {
      amount = taxAmount;
    } else if (label == 'Total') {
      amount = totalAmount;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            'PKR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  /// Build customer selector
  Widget _buildCustomerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (_selectedCustomerId == null)
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Select Customer', style: TextStyle(fontSize: 11)),
              onPressed: _showCustomerSelector,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          FutureBuilder<Customer?>(
            future: _selectedCustomerId == null
                ? Future.value(Customer(
                    name: 'Walk-In Customer',
                    createdAt: DateTime.now(),
                  ))
                : CustomerDAO().getCustomerById(_selectedCustomerId!),
            builder: (context, snapshot) {
              final customerName = snapshot.data?.name ?? 'Customer #$_selectedCustomerId';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedCustomerId = null),
                      child: const Icon(Icons.close, size: 14, color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  /// Show customer selector dialog
  void _showCustomerSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                children: [
                TextField(
                  controller: _customerSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),
                const Text('Customers:'),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: FutureBuilder<List<Customer>>(
                      future: () async {
                        final customerDAO = CustomerDAO();
                        final searchQuery = _customerSearchController.text.toLowerCase();
                        
                        if (searchQuery.isEmpty) {
                          return await customerDAO.getAllCustomers();
                        } else {
                          return await customerDAO.searchCustomers(searchQuery);
                        }
                      }(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        
                        final customers = snapshot.data ?? [];
                        
                        if (customers.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No customers found'),
                          );
                        }
                        
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Walk-In Customer'),
                              subtitle: const Text('Pay now, no account'),
                              onTap: () {
                                setState(() => _selectedCustomerId = null);
                                Navigator.pop(context);
                              },
                            ),
                            const Divider(),
                            ...customers.map(
                              (customer) => ListTile(
                                title: Text(customer.name),
                                subtitle: Text(
                                  '${customer.type} • ${customer.phone ?? "No phone"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  setState(() => _selectedCustomerId = customer.id);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
