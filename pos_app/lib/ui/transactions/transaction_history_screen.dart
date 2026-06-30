/// Transaction History Screen
/// View all historical transactions with filtering and search capabilities
/// Features: Date range filtering, customer filtering, payment method filtering, detailed transaction view

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/data/models/sale_model.dart';
import 'package:pos_app/data/local/sale_dao.dart';
import 'package:pos_app/data/local/customer_dao.dart';
import 'package:pos_app/data/models/customer_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _saleDAO = SaleDAO();
  final _customerDAO = CustomerDAO();
  final _searchController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPaymentMethod;
  int? _selectedCustomerId;
  List<Sale> _allTransactions = [];
  List<Sale> _filteredTransactions = [];
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _saleDAO.getAllSales();
      final customers = await _customerDAO.getAllCustomers();
      
      setState(() {
        _allTransactions = transactions;
        _customers = customers;
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredTransactions = _allTransactions.where((sale) {
      // Date range filter
      if (_startDate != null && sale.createdAt.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null) {
        final endOfDay =
            _endDate!.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        if (sale.createdAt.isAfter(endOfDay)) {
          return false;
        }
      }

      // Payment method filter
      if (_selectedPaymentMethod != null &&
          sale.paymentMethod != _selectedPaymentMethod) {
        return false;
      }

      // Customer filter
      if (_selectedCustomerId != null &&
          sale.customerId != _selectedCustomerId) {
        return false;
      }

      // Search filter
      final searchTerm = _searchController.text.toLowerCase();
      if (searchTerm.isNotEmpty) {
        return sale.id.toString().contains(searchTerm) ||
            sale.totalAmount.toString().contains(searchTerm) ||
            sale.paymentMethod.toLowerCase().contains(searchTerm);
      }

      return true;
    }).toList();

    // Apply sorting
    _sortTransactions();
  }

  void _sortTransactions() {
    switch (_sortBy) {
      case 'date_desc':
        _filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        _filteredTransactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'amount_desc':
        _filteredTransactions.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'amount_asc':
        _filteredTransactions.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedPaymentMethod = null;
      _selectedCustomerId = null;
      _searchController.clear();
      _sortBy = 'date_desc';
      _applyFilters();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  String _getCustomerName(int? customerId) {
    if (customerId == null) return 'Walk-In';
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      return customer.name;
    } catch (e) {
      return 'Customer #$customerId';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters Section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by ID or amount...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Filter Buttons Row 1
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Date Range Button
                            ElevatedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _startDate != null && _endDate != null
                                    ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                                    : 'Date Range',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _startDate != null
                                    ? Colors.blue
                                    : Colors.grey[300],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Payment Method Filter
                            PopupMenuButton<String>(
                              initialValue: _selectedPaymentMethod,
                              onSelected: (value) {
                                setState(() {
                                  _selectedPaymentMethod =
                                      value == _selectedPaymentMethod
                                          ? null
                                          : value;
                                  _applyFilters();
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return ['CASH', 'CARD', 'CREDIT'].map((method) {
                                  return PopupMenuItem<String>(
                                    value: method,
                                    child: Text(method),
                                  );
                                }).toList();
                              },
                              child: Chip(
                                label: Text(
                                  _selectedPaymentMethod ?? 'Payment Method',
                                ),
                                backgroundColor:
                                    _selectedPaymentMethod != null
                                        ? Colors.blue
                                        : Colors.grey[300],
                                deleteIcon:
                                    _selectedPaymentMethod != null
                                        ? const Icon(Icons.close)
                                        : null,
                                onDeleted: _selectedPaymentMethod != null
                                    ? () {
                                        setState(() {
                                          _selectedPaymentMethod = null;
                                          _applyFilters();
                                        });
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Customer Filter
                            if (_customers.isNotEmpty)
                              PopupMenuButton<int?>(
                                initialValue: _selectedCustomerId,
                                onSelected: (value) {
                                  setState(() {
                                    _selectedCustomerId = value;
                                    _applyFilters();
                                  });
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    PopupMenuItem<int?>(
                                      value: null,
                                      child: const Text('All Customers'),
                                    ),
                                    const PopupMenuDivider(),
                                    ..._customers.map((customer) {
                                      return PopupMenuItem<int?>(
                                        value: customer.id,
                                        child: Text(customer.name),
                                      );
                                    }),
                                  ];
                                },
                                child: Chip(
                                  label: Text(
                                    _selectedCustomerId != null
                                        ? _getCustomerName(
                                            _selectedCustomerId)
                                        : 'Customer',
                                  ),
                                  backgroundColor:
                                      _selectedCustomerId != null
                                          ? Colors.blue
                                          : Colors.grey[300],
                                  deleteIcon:
                                      _selectedCustomerId != null
                                          ? const Icon(Icons.close)
                                          : null,
                                  onDeleted:
                                      _selectedCustomerId != null
                                          ? () {
                                              setState(() {
                                                _selectedCustomerId =
                                                    null;
                                                _applyFilters();
                                              });
                                            }
                                          : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sort and Reset Buttons
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isExpanded: true,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _sortBy = value;
                                    _applyFilters();
                                  });
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'date_desc',
                                  child: Text('Newest First'),
                                ),
                                DropdownMenuItem(
                                  value: 'date_asc',
                                  child: Text('Oldest First'),
                                ),
                                DropdownMenuItem(
                                  value: 'amount_desc',
                                  child: Text('Highest Amount'),
                                ),
                                DropdownMenuItem(
                                  value: 'amount_asc',
                                  child: Text('Lowest Amount'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transaction Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Total: ${_filteredTransactions.length} transactions',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

                // Transactions List
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction =
                                _filteredTransactions[index];
                            return _TransactionCard(
                              transaction: transaction,
                              customerName: _getCustomerName(
                                transaction.customerId,
                              ),
                              onTap: () => _showTransactionDetails(
                                transaction,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showTransactionDetails(Sale transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _DetailRow(
                  label: 'Transaction ID',
                  value: '#${transaction.id}',
                ),
                _DetailRow(
                  label: 'Date & Time',
                  value: DateFormat('MMM d, yyyy - h:mm a')
                      .format(transaction.createdAt),
                ),
                _DetailRow(
                  label: 'Customer',
                  value: _getCustomerName(transaction.customerId),
                ),
                _DetailRow(
                  label: 'Payment Method',
                  value: transaction.paymentMethod,
                  valueColor: _getPaymentMethodColor(
                    transaction.paymentMethod,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Amount Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Subtotal',
                  value: 'PKR ${transaction.subtotal.toStringAsFixed(2)}',
                ),
                if (transaction.discountAmount > 0)
                  _DetailRow(
                    label: 'Discount (${transaction.discountPercentage}%)',
                    value: '-PKR ${transaction.discountAmount.toStringAsFixed(2)}',
                    valueColor: Colors.red,
                  ),
                if (transaction.taxAmount > 0)
                  _DetailRow(
                    label: 'Tax',
                    value: '+PKR ${transaction.taxAmount.toStringAsFixed(2)}',
                    valueColor: Colors.orange,
                  ),
                const Divider(),
                _DetailRow(
                  label: 'Total Amount',
                  value: 'PKR ${transaction.totalAmount.toStringAsFixed(2)}',
                  isHighlight: true,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Status',
                  value: transaction.status,
                  valueColor: _getStatusColor(transaction.status),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _TransactionCard extends StatelessWidget {
  final Sale transaction;
  final String customerName;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.customerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getPaymentMethodColor(transaction.paymentMethod),
          child: Icon(
            _getPaymentMethodIcon(transaction.paymentMethod),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              'ID: #${transaction.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPaymentMethodColor(transaction.paymentMethod)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.paymentMethod,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      _getPaymentMethodColor(transaction.paymentMethod),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              customerName,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              DateFormat('MMM d, yyyy - h:mm a').format(transaction.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PKR ${transaction.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              transaction.status,
              style: TextStyle(
                fontSize: 11,
                color: _getStatusColor(transaction.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.payments;
      case 'CARD':
        return Icons.credit_card;
      case 'CREDIT':
        return Icons.account_balance;
      default:
        return Icons.receipt;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isHighlight;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              fontSize: isHighlight ? 14 : 13,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlight ? 15 : 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
