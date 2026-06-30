import 'package:flutter/material.dart';
import '../models/demand_prediction_result.dart';
import '../services/demand_prediction_service.dart';
import '../widgets/sales_trend_chart.dart';
import '../../../services/database_helper.dart';

/// Main UI Screen for Demand Prediction
/// Displays AI analysis results and recommendations for a product
class DemandPredictionScreen extends StatefulWidget {
  const DemandPredictionScreen({Key? key}) : super(key: key);

  @override
  State<DemandPredictionScreen> createState() => _DemandPredictionScreenState();
}

class _DemandPredictionScreenState extends State<DemandPredictionScreen> {
  late DemandPredictionResult predictionResult;
  late String selectedProduct;
  
  // Mutable product data - can be modified at runtime
  late Map<String, Map<String, dynamic>> products;
  
  // Dummy data for demonstration
  final Map<String, Map<String, dynamic>> dummyProducts = {
    'Rice (10kg)': {
      'last7DaysSales': [45, 42, 40, 55, 60, 65, 68],
      'currentStock': 50,
      'minimumThreshold': 100,
      'costPrice': 1200.0,
      'sellingPrice': 1500.0,
    },
    'Wheat Flour (5kg)': {
      'last7DaysSales': [80, 75, 70, 60, 50, 45, 40],
      'currentStock': 200,
      'minimumThreshold': 150,
      'costPrice': 250.0,
      'sellingPrice': 400.0,
    },
    'Cooking Oil (1L)': {
      'last7DaysSales': [30, 32, 30, 31, 32, 30, 31],
      'currentStock': 80,
      'minimumThreshold': 50,
      'costPrice': 150.0,
      'sellingPrice': 250.0,
    },
    'Sugar (5kg)': {
      'last7DaysSales': [25, 28, 30, 25, 20, 18, 15],
      'currentStock': 15,
      'minimumThreshold': 60,
      'costPrice': 380.0,
      'sellingPrice': 500.0,
    },
  };

  @override
  void initState() {
    super.initState();
    // Initialize mutable products from dummy data
    products = Map.from(dummyProducts);
    selectedProduct = products.keys.first;
    _updatePrediction();
    _loadProductsFromDatabase();
  }

  /// Load products from SQLite database
  Future<void> _loadProductsFromDatabase() async {
    try {
      final dbProducts = await DatabaseHelper().getAllProducts();
      if (dbProducts.isNotEmpty) {
        setState(() {
          products = dbProducts;
          if (!products.containsKey(selectedProduct)) {
            selectedProduct = products.keys.first;
          }
          _updatePrediction();
        });
      }
    } catch (e) {
      print('Error loading products from database: $e');
    }
  }

  /// Analyzes the selected product using AI logic
  void _updatePrediction() {
    final productData = products[selectedProduct]!;
    
    predictionResult = DemandPredictionService.analyzeDemand(
      productName: selectedProduct,
      last7DaysSales: List<int>.from(productData['last7DaysSales']),
      currentStock: productData['currentStock'],
      minimumStockThreshold: productData['minimumThreshold'],
      costPrice: productData['costPrice'],
      sellingPrice: productData['sellingPrice'],
    );
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartStock AI Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28, color: Colors.black),
            tooltip: 'Add New Product',
            onPressed: () => _showDataInputDialog(isNew: true),
          ),
          IconButton(
            icon: const Icon(Icons.list, size: 28, color: Colors.black),
            tooltip: 'Manage Products',
            onPressed: _showProductsManagement,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AI System Introduction
            _buildIntroductionSection(),
            
            // Individual Product Cards
            _buildProductCardsSection(),
            
            // Collective Analysis Section
            _buildCollectiveAnalysisSection(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds cards for each product showing individual analysis
  Widget _buildProductCardsSection() {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'No products added yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Products Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${products.length} products',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        ...products.entries.map((entry) {
          final productName = entry.key;
          final productData = entry.value;
          return _buildProductCard(productName, productData);
        }).toList(),
      ],
    );
  }

  /// Builds individual product card with analysis
  Widget _buildProductCard(String productName, Map<String, dynamic> productData) {
    final result = DemandPredictionService.analyzeDemand(
      productName: productName,
      last7DaysSales: List<int>.from(productData['last7DaysSales']),
      currentStock: productData['currentStock'],
      minimumStockThreshold: productData['minimumThreshold'],
      costPrice: productData['costPrice'],
      sellingPrice: productData['sellingPrice'],
    );

    final trendColor = result.demandTrend == 'Increasing'
        ? Colors.green
        : result.demandTrend == 'Decreasing'
            ? Colors.red
            : Colors.grey;

    final isLowStock = result.lowStockAlert;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: trendColor.withOpacity(0.2),
                              border: Border.all(color: trendColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              result.demandTrend,
                              style: TextStyle(
                                color: trendColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isLowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '⚠️ Low Stock',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 24),
                      onPressed: () => _showDataInputDialog(
                        isNew: false,
                        productName: productName,
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                      onPressed: () => _deleteProduct(productName),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stock and Sales Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProductInfoBox(
                  label: 'Stock',
                  value: '${productData['currentStock']}',
                  subtext: 'Min: ${productData['minimumThreshold']}',
                  color: isLowStock ? Colors.red : Colors.blue,
                ),
                _ProductInfoBox(
                  label: 'Avg Daily',
                  value: result.averageDailySales.toStringAsFixed(1),
                  subtext: 'units/day',
                  color: Colors.orange,
                ),
                _ProductInfoBox(
                  label: 'Profit',
                  value: result.profit.toStringAsFixed(0),
                  subtext: 'PKR',
                  color: result.profit >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // AI Suggestion
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Suggestion',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.suggestion,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // View Details Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showProductDetails(productName, productData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Detailed Analysis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows detailed analysis for a specific product
  void _showProductDetails(String productName, Map<String, dynamic> productData) {
    final result = DemandPredictionService.analyzeDemand(
      productName: productName,
      last7DaysSales: List<int>.from(productData['last7DaysSales']),
      currentStock: productData['currentStock'],
      minimumStockThreshold: productData['minimumThreshold'],
      costPrice: productData['costPrice'],
      sellingPrice: productData['sellingPrice'],
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Detailed info
                _DetailInfoRow('Demand Trend', result.demandTrend),
                _DetailInfoRow('Average Daily Sales', result.averageDailySales.toStringAsFixed(1) + ' units'),
                _DetailInfoRow('Current Stock', productData['currentStock'].toString()),
                _DetailInfoRow('Minimum Threshold', productData['minimumThreshold'].toString()),
                _DetailInfoRow('Suggested Reorder', result.suggestedReorderQty.toString()),
                _DetailInfoRow('Total Profit (7 days)', 'PKR ${result.profit.toStringAsFixed(2)}'),
                _DetailInfoRow('Low Stock Alert', result.lowStockAlert ? 'Yes ⚠️' : 'No ✓'),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                Text(
                  'Sales Chart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SalesTrendChart(
                  productName: productName,
                  last7DaysSales: productData['last7DaysSales'],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Detailed Analysis',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DemandPredictionService.generateDetailedAnalysis(
                    productName: productName,
                    result: result,
                    currentStock: productData['currentStock'],
                    minimumStockThreshold: productData['minimumThreshold'],
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey[700],
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds collective analysis section
  Widget _buildCollectiveAnalysisSection() {
    if (products.isEmpty) return const SizedBox.shrink();

    // Calculate collective metrics
    int totalStock = 0;
    int totalThreshold = 0;
    double totalProfit = 0;
    int lowStockCount = 0;
    int increasingTrendCount = 0;
    int decreasingTrendCount = 0;
    double totalAverageSales = 0;

    for (final entry in products.entries) {
      final productName = entry.key;
      final productData = entry.value;
      final result = DemandPredictionService.analyzeDemand(
        productName: productName,
        last7DaysSales: List<int>.from(productData['last7DaysSales']),
        currentStock: productData['currentStock'],
        minimumStockThreshold: productData['minimumThreshold'],
        costPrice: productData['costPrice'],
        sellingPrice: productData['sellingPrice'],
      );

      totalStock += productData['currentStock'] as int;
      totalThreshold += productData['minimumThreshold'] as int;
      totalProfit += result.profit;
      if (result.lowStockAlert) lowStockCount++;
      if (result.demandTrend == 'Increasing') increasingTrendCount++;
      if (result.demandTrend == 'Decreasing') decreasingTrendCount++;
      totalAverageSales += result.averageDailySales;
    }

    final totalProducts = products.length;
    final inventoryHealth = totalStock >= totalThreshold ? 'Good' : 'Low';
    final inventoryHealthColor = totalStock >= totalThreshold ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(thickness: 2),
          const SizedBox(height: 20),
          
          const Text(
            '📈 Collective Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _CollectiveInfoCard(
                  title: 'Total Inventory',
                  value: totalStock.toString(),
                  subtitle: 'Current Stock',
                  color: Colors.blue,
                  icon: Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CollectiveInfoCard(
                  title: 'Inventory Health',
                  value: inventoryHealth,
                  subtitle: totalStock >= totalThreshold ? 'Above Threshold' : 'Below Threshold',
                  color: inventoryHealthColor,
                  icon: inventoryHealth == 'Good' ? Icons.check_circle : Icons.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _CollectiveInfoCard(
                  title: 'Total Revenue',
                  value: 'PKR ${totalProfit.toStringAsFixed(0)}',
                  subtitle: '7-day profit',
                  color: totalProfit >= 0 ? Colors.green : Colors.red,
                  icon: totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CollectiveInfoCard(
                  title: 'Avg Daily Sales',
                  value: totalAverageSales.toStringAsFixed(1),
                  subtitle: 'All products',
                  color: Colors.orange,
                  icon: Icons.show_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Alerts Section
          if (lowStockCount > 0)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Low Stock Alert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$lowStockCount product(s) have low stock',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Market Trends
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Market Trends',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Increasing Demand',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$increasingTrendCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'products',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stable Demand',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalProducts - increasingTrendCount - decreasingTrendCount}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const Text(
                              'products',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Decreasing Demand',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$decreasingTrendCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text(
                              'products',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows dialog to manually input or edit product data
  void _showDataInputDialog({bool isNew = false, String? productName}) {
    final isEditing = !isNew && (productName != null && products.containsKey(productName));
    final productData = isEditing ? products[productName]! : null;
    
    final nameController = TextEditingController(
      text: isEditing ? productName : '',
    );
    final currentStockController = TextEditingController(
      text: isEditing ? productData!['currentStock'].toString() : '',
    );
    final minThresholdController = TextEditingController(
      text: isEditing ? productData!['minimumThreshold'].toString() : '',
    );
    final costPriceController = TextEditingController(
      text: isEditing ? productData!['costPrice'].toString() : '',
    );
    final sellingPriceController = TextEditingController(
      text: isEditing ? productData!['sellingPrice'].toString() : '',
    );
    
    final salesControllers = List.generate(
      7,
      (index) => TextEditingController(
        text: isEditing ? productData!['last7DaysSales'][index].toString() : '',
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Product Data' : 'Add New Product',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Product Name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'e.g., Rice (10kg)',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Last 7 Days Sales
                const Text(
                  'Last 7 Days Sales (One per day)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                // First row (Days 1-4)
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: salesControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Day ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Second row (Days 5-7)
                Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: salesControllers[index + 4],
                          decoration: InputDecoration(
                            labelText: 'Day ${index + 5}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Current Stock
                TextField(
                  controller: currentStockController,
                  decoration: InputDecoration(
                    labelText: 'Current Stock',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Minimum Threshold
                TextField(
                  controller: minThresholdController,
                  decoration: InputDecoration(
                    labelText: 'Minimum Threshold',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Cost Price
                TextField(
                  controller: costPriceController,
                  decoration: InputDecoration(
                    labelText: 'Cost Price (PKR)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Selling Price
                TextField(
                  controller: sellingPriceController,
                  decoration: InputDecoration(
                    labelText: 'Selling Price (PKR)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      onPressed: () {
                        _saveProductData(
                          nameController,
                          currentStockController,
                          minThresholdController,
                          costPriceController,
                          sellingPriceController,
                          salesControllers,
                          isEditing,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Saves the product data from the dialog
  void _saveProductData(
    TextEditingController nameController,
    TextEditingController currentStockController,
    TextEditingController minThresholdController,
    TextEditingController costPriceController,
    TextEditingController sellingPriceController,
    List<TextEditingController> salesControllers,
    bool isEditing,
  ) {
    // Validate inputs
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter product name')),
      );
      return;
    }

    try {
      // Remove old product if editing with a different name
      if (isEditing && nameController.text != selectedProduct) {
        products.remove(selectedProduct);
      }

      // Parse sales data
      final last7DaysSales = salesControllers
          .map((controller) => int.parse(controller.text))
          .toList();

      // Create product data
      products[nameController.text] = {
        'last7DaysSales': last7DaysSales,
        'currentStock': int.parse(currentStockController.text),
        'minimumThreshold': int.parse(minThresholdController.text),
        'costPrice': double.parse(costPriceController.text),
        'sellingPrice': double.parse(sellingPriceController.text),
      };

      // Save to database
      DatabaseHelper().saveProduct(
        name: nameController.text,
        last7DaysSales: last7DaysSales,
        currentStock: int.parse(currentStockController.text),
        minimumThreshold: int.parse(minThresholdController.text),
        costPrice: double.parse(costPriceController.text),
        sellingPrice: double.parse(sellingPriceController.text),
      );

      // Update UI
      setState(() {
        selectedProduct = nameController.text;
        _updatePrediction();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product data saved successfully! 💾')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Please check all fields. $e')),
      );
    }
  }

  /// Shows product management screen with all products
  void _showProductsManagement() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Total Products: ${products.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productName = products.keys.elementAt(index);
                    final productData = products[productName]!;
                    final stock = productData['currentStock'];
                    final threshold = productData['minimumThreshold'];
                    final isLowStock = stock < threshold;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Stock: $stock/${threshold}${isLowStock ? ' ⚠️' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLowStock ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit button
                            IconButton(
                              icon: const Icon(Icons.edit, size: 24, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
                                _showDataInputDialog(
                                  isNew: false,
                                  productName: productName,
                                );
                              },
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete, size: 24, color: Colors.red),
                              onPressed: () {
                                _deleteProduct(productName);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDataInputDialog(isNew: true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Deletes a product from the list
  void _deleteProduct(String productName) {
    // Delete from database
    DatabaseHelper().deleteProduct(productName);
    
    setState(() {
      products.remove(productName);
      if (selectedProduct == productName && products.isNotEmpty) {
        selectedProduct = products.keys.first;
        _updatePrediction();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted: $productName 🗑️')),
    );
  }

  /// Builds the introduction section explaining the AI system
  Widget _buildIntroductionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.indigo[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 AI-Powered Demand Prediction',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'English:\nThis system analyzes recent sales trends using AI-based logic to help businesses manage stock efficiently.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'اردو:\nیہ نظام حالیہ فروخت کے ڈیٹا کو تجزیہ کر کے اسٹاک مینجمنٹ میں ذہین فیصلے سجھاتا ہے۔',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the product selector dropdown
  Widget _buildProductSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.indigo[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedProduct,
          underline: const SizedBox(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: products.keys.map((product) {
            return DropdownMenuItem(
              value: product,
              child: Text(product),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedProduct = value;
                _updatePrediction();
              });
            }
          },
        ),
      ),
    );
  }

  /// Builds the main demand trend card
  Widget _buildDemandTrendCard() {
    final trendColor = predictionResult.demandTrend == 'Increasing'
        ? Colors.green
        : predictionResult.demandTrend == 'Decreasing'
            ? Colors.red
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              trendColor.withOpacity(0.1),
              trendColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Demand Trend',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.2),
                    border: Border.all(color: trendColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    predictionResult.demandTrend,
                    style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${DemandPredictionService.getTrendEmoji(predictionResult.demandTrend)} ${predictionResult.demandTrend}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Avg Daily Sales: ${predictionResult.averageDailySales.toStringAsFixed(1)} units',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the stock status card
  Widget _buildStockStatusCard(Map<String, dynamic> productData) {
    final currentStock = productData['currentStock'];
    final minThreshold = productData['minimumThreshold'];
    final isLowStock = predictionResult.lowStockAlert;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📦 Stock Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⚠️ Low Stock',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StockInfo(
                  label: 'Current',
                  value: currentStock.toString(),
                  color: Colors.blue,
                ),
                _StockInfo(
                  label: 'Minimum',
                  value: minThreshold.toString(),
                  color: Colors.orange,
                ),
                _StockInfo(
                  label: 'Reorder Qty',
                  value: predictionResult.suggestedReorderQty.toString(),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the profit analysis card
  Widget _buildProfitAnalysisCard() {
    final isProfit = predictionResult.profit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Profit/Loss',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PKR ${predictionResult.profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: profitColor,
                  ),
                ),
              ],
            ),
            Text(
              isProfit ? '💰' : '📉',
              style: const TextStyle(fontSize: 32),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the recommendation card
  Widget _buildRecommendationCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 AI Recommendation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              predictionResult.suggestion,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the detailed analysis section
  Widget _buildDetailedAnalysisSection(Map<String, dynamic> productData) {
    final analysis = DemandPredictionService.generateDetailedAnalysis(
      productName: selectedProduct,
      result: predictionResult,
      currentStock: productData['currentStock'],
      minimumStockThreshold: productData['minimumThreshold'],
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Detailed Analysis Report',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              analysis,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.grey[700],
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget to display stock information
class _StockInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StockInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Helper widget to display product information in card
class _ProductInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;

  const _ProductInfoBox({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for detailed info rows
class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for collective analysis cards
class _CollectiveInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _CollectiveInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
