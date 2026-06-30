/// Home Screen / Dashboard
/// Premium analytics dashboard with comprehensive metrics and insights
/// Features: Real-time metrics, trending indicators, top products, alerts, customizable widgets

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/core/services/auth_service.dart';
import 'package:pos_app/core/services/transaction_service.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/repositories/product_repository.dart';
import 'package:pos_app/data/local/sale_dao.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _productRepository = ProductRepository();
  final _saleDAO = SaleDAO();

  late Future<Map<String, dynamic>> _dashboardData;
  bool _showCustomizationMenu = false;
  List<String> _visibleWidgets = [
    'alerts',
    'metrics',
    'today_summary',
    'top_products',
    'recent_transactions',
    'insights',
    'menu'
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedPreferences();
    _dashboardData = _loadDashboardData();
    
    // Listen to transaction updates and refresh dashboard
    Future.microtask(() {
      context.read<TransactionService>().addListener(_onTransactionUpdate);
    });
  }

  @override
  void dispose() {
    context.read<TransactionService>().removeListener(_onTransactionUpdate);
    super.dispose();
  }

  /// Called when a new transaction is created
  void _onTransactionUpdate() {
    setState(() {
      _dashboardData = _loadDashboardData();
    });
  }

  /// Load customization preferences from cache
  void _loadCachedPreferences() {
    // In a real app, this would load from SharedPreferences
    // For now, all widgets are visible by default
  }

  /// Toggle widget visibility
  void _toggleWidget(String widgetId) {
    setState(() {
      if (_visibleWidgets.contains(widgetId)) {
        _visibleWidgets.remove(widgetId);
      } else {
        _visibleWidgets.add(widgetId);
      }
    });
  }

  /// Load comprehensive dashboard data
  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      final allProducts = await _productRepository.getAllProducts();
      final lowStockProducts =
          await _productRepository.getLowStockProducts();

      // Sort products by stock quantity to find top products
      final topProducts = [...allProducts]
        ..sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));

      int totalValue = 0;
      for (final product in allProducts) {
        totalValue += (product.price * product.stockQuantity).toInt();
      }

      // Get today's sales from database
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final todaysSales = await _saleDAO.getAllSales(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Calculate real metrics from today's sales
      double todaysSalesTotal = 0;
      int todaysItems = 0;
      for (final sale in todaysSales) {
        todaysSalesTotal += sale.totalAmount;
        if (sale.id != null) {
          final saleItems = await _saleDAO.getSaleItems(sale.id!);
          todaysItems += saleItems.length;
        }
      }

      // Calculate trends based on comparison with previous period (yesterday)
      final yesterday = startOfDay.subtract(const Duration(days: 1));
      final yesterdaysEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      
      final yesterdaysSales = await _saleDAO.getAllSales(
        startDate: yesterday,
        endDate: yesterdaysEnd,
      );
      
      double yesterdaysSalesTotal = 0;
      int yesterdaysItems = 0;
      for (final sale in yesterdaysSales) {
        yesterdaysSalesTotal += sale.totalAmount;
        if (sale.id != null) {
          final saleItems = await _saleDAO.getSaleItems(sale.id!);
          yesterdaysItems += saleItems.length;
        }
      }

      // Calculate trend percentages
      int productTrend = 0;
      int stockTrend = 0;
      int valueTrend = 0;

      if (yesterdaysSalesTotal > 0) {
        valueTrend = ((todaysSalesTotal - yesterdaysSalesTotal) / yesterdaysSalesTotal * 100).toInt();
      }
      if (yesterdaysItems > 0) {
        stockTrend = ((todaysItems - yesterdaysItems) / yesterdaysItems * 100).toInt();
      }

      // Generate real recent transactions from today's sales
      final recentTransactions = <Map<String, dynamic>>[];
      for (final sale in todaysSales.take(5)) {
        int itemCount = 0;
        if (sale.id != null) {
          final saleItems = await _saleDAO.getSaleItems(sale.id!);
          itemCount = saleItems.length;
        }
        recentTransactions.add({
          'id': 'INV${sale.id}',
          'amount': sale.totalAmount.toInt(),
          'items': itemCount,
          'time': sale.createdAt.toString().split('.')[0],
        });
      }

      // Calculate health score based on various metrics
      int healthScore = 75;
      if (lowStockProducts.isEmpty) healthScore += 5;
      if (todaysSales.isNotEmpty) healthScore += 10;
      if (valueTrend > 0) healthScore += 10;

      return {
        'totalProducts': allProducts.length,
        'lowStockCount': lowStockProducts.length,
        'totalInventoryValue': totalValue.toDouble(),
        'totalStock': allProducts.fold<int>(0, (sum, p) => sum + p.stockQuantity),
        'productTrend': productTrend,
        'stockTrend': stockTrend,
        'valueTrend': valueTrend,
        'topProducts': topProducts.take(5).toList(),
        'lowStockProducts': lowStockProducts.take(5).toList(),
        'recentTransactions': recentTransactions,
        'todaysSales': todaysSalesTotal.toInt(),
        'todaysTransactions': todaysSales.length,
        'todaysItems': todaysItems,
        'healthScore': healthScore.clamp(0, 100),
      };
    } catch (e) {
      print('Error loading dashboard data: $e');
      return {
        'totalProducts': 0,
        'lowStockCount': 0,
        'totalInventoryValue': 0.0,
        'totalStock': 0,
        'topProducts': [],
        'recentTransactions': [],
        'todaysSales': 0,
        'todaysTransactions': 0,
        'todaysItems': 0,
        'healthScore': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        title: const Text(
          'Smart POS Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              setState(() => _showCustomizationMenu = !_showCustomizationMenu);
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await _authService.logout();
                  if (mounted) {
                    Navigator.of(context)
                        .pushReplacementNamed(AppConstants.ROUTE_LOGIN);
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardData = _loadDashboardData();
              });
              await _dashboardData;
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.DEFAULT_PADDING),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient header with user profile and health score
                  _buildHeaderSection(data),
                  const SizedBox(height: 24),

                  // Customization menu
                  if (_showCustomizationMenu) ...[
                    _buildCustomizationMenu(),
                    const SizedBox(height: 20),
                  ],

                  // Alerts banner (high priority)
                  if (_visibleWidgets.contains('alerts'))
                    ..._buildAlertsBanner(data),

                  // Key metrics with trends
                  if (_visibleWidgets.contains('metrics')) ...[
                    Text(
                      'Key Metrics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricsGrid(data),
                    const SizedBox(height: 24),
                  ],

                  // Today's summary
                  if (_visibleWidgets.contains('today_summary')) ...[
                    Text(
                      "Today's Performance",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildTodaysSummary(data),
                    const SizedBox(height: 24),
                  ],

                  // Top products
                  if (_visibleWidgets.contains('top_products')) ...[
                    Text(
                      'Top Performing Products',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildTopProductsList(data),
                    const SizedBox(height: 24),
                  ],

                  // Recent transactions
                  if (_visibleWidgets.contains('recent_transactions')) ...[
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildRecentTransactions(data),
                    const SizedBox(height: 24),
                  ],

                  // Insights section
                  if (_visibleWidgets.contains('insights')) ...[
                    Text(
                      'Business Insights',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildInsights(data),
                    const SizedBox(height: 24),
                  ],

                  // Navigation menu
                  if (_visibleWidgets.contains('menu')) ...[
                    Text(
                      'Quick Access',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildMenuGrid(context),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildQuickActionButtons(context),
    );
  }

  /// Build header with user profile and health score
  Widget _buildHeaderSection(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manager Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Health score bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Business Health',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${data['healthScore'] ?? 0}/100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (data['healthScore'] ?? 0) / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    (data['healthScore'] ?? 0) >= 80
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build customization menu
  Widget _buildCustomizationMenu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Show/Hide Widgets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'alerts',
                'metrics',
                'today_summary',
                'top_products',
                'recent_transactions',
                'insights',
                'menu'
              ]
                  .map(
                    (widget) => FilterChip(
                      label: Text(widget.replaceAll('_', ' ').toUpperCase()),
                      selected: _visibleWidgets.contains(widget),
                      onSelected: (_) => _toggleWidget(widget),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build alerts banner
  List<Widget> _buildAlertsBanner(Map<String, dynamic> data) {
    final alerts = <String>[];
    if ((data['lowStockCount'] ?? 0) > 0) {
      alerts.add('${data['lowStockCount']} items low on stock');
    }
    if ((data['healthScore'] ?? 100) < 70) {
      alerts.add('Business health below optimal level');
    }

    if (alerts.isEmpty) {
      return [];
    }

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: alerts
                    .map((alert) => Text(
                          alert,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  /// Build metrics grid with trending indicators
  Widget _buildMetricsGrid(Map<String, dynamic> data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _MetricCard(
          title: 'Total Products',
          value: '${data['totalProducts'] ?? 0}',
          icon: Icons.shopping_bag,
          color: Colors.blue,
          trend: data['productTrend'] ?? 0,
        ),
        _MetricCard(
          title: 'Total Stock',
          value: '${data['totalStock'] ?? 0}',
          icon: Icons.inventory,
          color: Colors.green,
          trend: data['stockTrend'] ?? 0,
        ),
        _MetricCard(
          title: 'Inventory Value',
          value: 'PKR ${(data['totalInventoryValue'] ?? 0).toStringAsFixed(0)}',
          icon: Icons.attach_money,
          color: Colors.purple,
          trend: data['valueTrend'] ?? 0,
        ),
        _MetricCard(
          title: 'Low Stock Items',
          value: '${data['lowStockCount'] ?? 0}',
          icon: Icons.warning,
          color: Colors.orange,
          trend: 0,
          isAlert: true,
        ),
      ],
    );
  }

  /// Build today's summary section
  Widget _buildTodaysSummary(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Today',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PKR ${data['todaysSales'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data['todaysTransactions'] ?? 0} transactions',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items Sold',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data['todaysItems'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Units',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build top products list
  Widget _buildTopProductsList(Map<String, dynamic> data) {
    final topProducts = data['topProducts'] as List? ?? [];

    if (topProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No products available',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: topProducts
          .asMap()
          .entries
          .map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (entry.value as Product).name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Stock: ${(entry.value as Product).stockQuantity}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'PKR ${(entry.value as Product).price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Build recent transactions list
  Widget _buildRecentTransactions(Map<String, dynamic> data) {
    final transactions = (data['recentTransactions'] as List?) ?? [];

    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No transactions today',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: transactions
          .map(
            (txn) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (txn as Map)['id'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${txn['items']} items',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'PKR ${txn['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          txn['time'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Build business insights section
  Widget _buildInsights(Map<String, dynamic> data) {
    final valueTrend = data['valueTrend'] ?? 0;
    final stockTrend = data['stockTrend'] ?? 0;
    final lowStockCount = data['lowStockCount'] ?? 0;
    final todaysSales = data['todaysSales'] ?? 0;
    final todaysTransactions = data['todaysTransactions'] ?? 0;
    final topProducts = (data['topProducts'] as List?) ?? [];
    final healthScore = data['healthScore'] ?? 0;
    
    // Determine trend colors and directions
    final salesTrendColor = valueTrend >= 0 ? Colors.green : Colors.red;
    final itemsTrendColor = stockTrend >= 0 ? Colors.green : Colors.red;
    final salesTrendIcon = valueTrend >= 0 ? Icons.trending_up : Icons.trending_down;
    final itemsTrendIcon = stockTrend >= 0 ? Icons.trending_up : Icons.trending_down;
    
    // Get top product name if available
    String topProductName = 'No sales yet';
    if (topProducts.isNotEmpty) {
      topProductName = topProducts[0].name ?? 'Unknown Product';
    }

    // Generate insights based on health score
    final insights = <Map<String, dynamic>>[];
    
    // Sales insight
    insights.add({
      'icon': salesTrendIcon,
      'title': 'Sales Revenue Trend',
      'description': 'Today: \$${todaysSales.toStringAsFixed(0)} (${valueTrend > 0 ? '+' : ''}${valueTrend}% vs yesterday)',
      'color': salesTrendColor,
    });
    
    // Inventory insight
    if (lowStockCount > 0) {
      insights.add({
        'icon': Icons.warning_rounded,
        'title': 'Low Stock Alert',
        'description': '$lowStockCount items need restocking soon',
        'color': Colors.orange,
      });
    } else {
      insights.add({
        'icon': Icons.check_circle,
        'title': 'Inventory Status',
        'description': 'All items are sufficiently stocked',
        'color': Colors.green,
      });
    }
    
    // Transaction insight
    insights.add({
      'icon': itemsTrendIcon,
      'title': 'Items Sold Trend',
      'description': 'Today: $todaysTransactions transactions (${stockTrend > 0 ? '+' : ''}${stockTrend}% vs yesterday)',
      'color': itemsTrendColor,
    });
    
    // Top performer insight
    insights.add({
      'icon': Icons.star,
      'title': 'Top Product',
      'description': topProductName,
      'color': Colors.purple,
    });
    
    // Health score insight
    insights.add({
      'icon': Icons.favorite,
      'title': 'Business Health',
      'description': 'Score: $healthScore/100 ${healthScore >= 80 ? '✓ Excellent' : healthScore >= 60 ? '• Good' : '✗ Needs Attention'}',
      'color': healthScore >= 80 ? Colors.green : healthScore >= 60 ? Colors.blue : Colors.orange,
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: insights
              .asMap()
              .entries
              .map((entry) {
                final isLast = entry.key == insights.length - 1;
                return Column(
                  children: [
                    _InsightItem(
                      icon: entry.value['icon'],
                      title: entry.value['title'],
                      description: entry.value['description'],
                      color: entry.value['color'],
                    ),
                    if (!isLast) const SizedBox(height: 12),
                  ],
                );
              })
              .toList(),
        ),
      ),
    );
  }

  /// Build menu grid with navigation options and badges
  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _MenuGridItem(
          title: 'POS / Billing',
          icon: Icons.shopping_cart,
          badge: null,
          color: Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_POS);
          },
        ),
        _MenuGridItem(
          title: 'Products',
          icon: Icons.shopping_bag,
          badge: null,
          color: Colors.green,
          onTap: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_PRODUCTS);
          },
        ),
        _MenuGridItem(
          title: 'Inventory',
          icon: Icons.inventory_2,
          badge: '5',
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_INVENTORY);
          },
        ),
        _MenuGridItem(
          title: 'Customers',
          icon: Icons.people,
          badge: null,
          color: Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_CUSTOMERS);
          },
        ),
        _MenuGridItem(
          title: 'Reports',
          icon: Icons.assessment,
          badge: null,
          color: Colors.red,
          onTap: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_REPORTS);
          },
        ),
        _MenuGridItem(
          title: 'Transactions',
          icon: Icons.receipt_long,
          badge: null,
          color: Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_TRANSACTIONS);
          },
        ),
        _MenuGridItem(
          title: 'Backup & Sync',
          icon: Icons.backup,
          badge: null,
          color: Colors.teal,
          onTap: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_BACKUP);
          },
        ),
      ],
    );
  }

  /// Build quick action floating buttons
  Widget _buildQuickActionButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'quick_stock',
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_INVENTORY);
          },
        ),
        const SizedBox(height: 12),
        FloatingActionButton.small(
          heroTag: 'quick_sale',
          backgroundColor: Colors.blue,
          child: const Icon(Icons.payment),
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_POS);
          },
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'quick_new_sale',
          backgroundColor: Colors.blue.shade600,
          child: const Icon(Icons.add_shopping_cart, size: 28),
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.ROUTE_POS);
          },
        ),
      ],
    );
  }
}

/// Metric card widget with trending indicator
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int trend;
  final bool isAlert;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = 0,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                if (trend != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trend > 0
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend > 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: trend > 0 ? Colors.green : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trend.abs()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: trend > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Insight item widget
class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Menu grid item widget
class _MenuGridItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _MenuGridItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  State<_MenuGridItem> createState() => _MenuGridItemState();
}

class _MenuGridItemState extends State<_MenuGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
      },
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.95)
            .animate(_animationController),
        child: Card(
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.15),
                  widget.color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: widget.color, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.badge != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          widget.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
