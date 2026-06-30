/// Customer Management Screen
/// Manage registered and walk-in customers
/// - View list of customers with statistics
/// - Add new customer
/// - Edit customer info
/// - View customer ledger/purchase history
/// - Quick action buttons (call, email, SMS)
/// - Advanced filtering and search

import 'package:flutter/material.dart';
import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/data/models/customer_model.dart';
import 'package:pos_app/data/local/customer_dao.dart';
import 'package:pos_app/data/local/ledger_entry_dao.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({Key? key}) : super(key: key);

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final CustomerDAO _customerDAO = CustomerDAO();
  final LedgerEntryDAO _ledgerDAO = LedgerEntryDAO();
  final _searchController = TextEditingController();
  bool _showOnlyRegistered = false;
  bool _showOnlyWithBalance = false;
  String _filterType = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Show add customer dialog
  void _showAddCustomerDialog({Customer? customer}) {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    String customerType = customer?.type ?? 'WALK_IN';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: customerType,
                items: ['WALK_IN', 'REGISTERED']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    customerType = value;
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }

              if (isEdit) {
                await _customerDAO.updateCustomer(
                  customer.copyWith(
                    name: nameController.text,
                    email: emailController.text.isEmpty
                        ? null
                        : emailController.text,
                    phone: phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    type: customerType,
                    updatedAt: DateTime.now(),
                  ),
                );
              } else {
                await _customerDAO.addCustomer(
                  Customer(
                    name: nameController.text,
                    email:
                        emailController.text.isEmpty ? null : emailController.text,
                    phone:
                        phoneController.text.isEmpty ? null : phoneController.text,
                    type: customerType,
                    createdAt: DateTime.now(),
                  ),
                );
              }

              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCustomerDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          _buildStatisticsHeader(),
          
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name or phone',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.DEFAULT_BORDER_RADIUS),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Registered'),
                        selected: _showOnlyRegistered,
                        onSelected: (value) {
                          setState(() => _showOnlyRegistered = value);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('With Balance'),
                        selected: _showOnlyWithBalance,
                        onSelected: (value) {
                          setState(() => _showOnlyWithBalance = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Customer list
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final customers = snapshot.data ?? [];

                if (customers.isEmpty) {
                  return const Center(
                    child: Text('No customers found'),
                  );
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerCard(customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build statistics header
  Widget _buildStatisticsHeader() {
    return FutureBuilder<List>(
      future: Future.wait([
        _customerDAO.getAllCustomers(),
        _customerDAO.getRegisteredCustomers(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final allCustomers = snapshot.data?[0] as List? ?? [];
        final registered = snapshot.data?[1] as List? ?? [];
        final walkIn = allCustomers.length - registered.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', allCustomers.length.toString(), Colors.blue),
              _buildStatCard('Registered', registered.length.toString(), Colors.green),
              _buildStatCard('Walk-In', walkIn.toString(), Colors.orange),
            ],
          ),
        );
      },
    );
  }

  /// Build stat card
  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Get customers based on filters
  Future<List<Customer>> _getCustomers() async {
    List<Customer> customers = [];
    
    if (_searchController.text.isEmpty) {
      if (_showOnlyRegistered) {
        customers = await _customerDAO.getRegisteredCustomers();
      } else {
        customers = await _customerDAO.getAllCustomers();
      }
    } else {
      customers = await _customerDAO.searchCustomers(_searchController.text);
    }

    // Filter by balance if needed
    if (_showOnlyWithBalance) {
      final filtered = <Customer>[];
      for (final customer in customers) {
        final balance = await _ledgerDAO.getOutstandingBalance(customer.id!);
        if (balance > 0) {
          filtered.add(customer);
        }
      }
      return filtered;
    }

    return customers;
  }

  /// Build customer card with real-time balance syncing
  Widget _buildCustomerCard(Customer customer) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<List>(
          future: Future.wait([
            _ledgerDAO.getOutstandingBalance(customer.id!),
            _ledgerDAO.getTotalCredit(customer.id!),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(customer.name),
                  subtitle: const Text('Loading balance...'),
                ),
              );
            }

            final balance = snapshot.data?[0] as double? ?? 0.0;
            final totalPaid = snapshot.data?[1] as double? ?? 0.0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: balance > 0 ? 2 : 1,
              child: Container(
                decoration: balance > 0
                    ? BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.orange.shade600,
                            width: 4,
                          ),
                        ),
                      )
                    : null,
                child: ListTile(
                  title: Text(customer.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${customer.type} • ${customer.phone ?? "No phone"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (balance > 0)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.orange.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_rounded,
                                      size: 14,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Outstanding: PKR ${balance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'All Paid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('View Details'),
                        onTap: () {
                          _showCustomerDetails(customer);
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () {
                          _showAddCustomerDialog(customer: customer);
                          setState(() {});
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Call'),
                        onTap: () {
                          if (customer.phone != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Call: ${customer.phone}')),
                            );
                          }
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Email'),
                        onTap: () {
                          if (customer.email != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Email: ${customer.email}')),
                            );
                          }
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () {
                          _showDeleteConfirmation(customer);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show customer details modal with real-time data
  Future<void> _showCustomerDetails(Customer customer) async {
    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(customer.name),
            content: SingleChildScrollView(
              child: FutureBuilder<List>(
                future: Future.wait([
                  _ledgerDAO.getOutstandingBalance(customer.id!),
                  _ledgerDAO.getTotalCredit(customer.id!),
                  _ledgerDAO.getCustomerEntries(customer.id!),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading data: ${snapshot.error}'),
                    );
                  }

                  final balance = snapshot.data?[0] as double? ?? 0.0;
                  final totalPaid = snapshot.data?[1] as double? ?? 0.0;
                  final entries = (snapshot.data?[2] as List?) ?? [];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer info section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.email, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customer.email ?? "No email",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customer.phone ?? "No phone",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Type: ${customer.type}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Balance section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: balance > 0
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: balance > 0
                                ? Colors.orange.shade300
                                : Colors.green.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  balance > 0
                                      ? 'Outstanding Balance'
                                      : 'Account Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: balance > 0
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                                Icon(
                                  balance > 0
                                      ? Icons.warning_rounded
                                      : Icons.check_circle,
                                  color: balance > 0
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'PKR ${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: balance > 0
                                    ? Colors.orange.shade900
                                    : Colors.green.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (totalPaid > 0)
                              Text(
                                'Total Paid: PKR ${totalPaid.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Transaction history section
                      Text(
                        'Transaction History (${entries.length} entries)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final isDebit = entry.type == 'DEBIT';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDebit
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDebit
                                        ? Colors.red.shade200
                                        : Colors.green.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isDebit
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                                size: 14,
                                                color: isDebit
                                                    ? Colors.red.shade600
                                                    : Colors.green.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${entry.type}: ${entry.description}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDebit
                                                      ? Colors.red.shade700
                                                      : Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            entry.createdAt.toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'PKR ${entry.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDebit
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content:
            Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _customerDAO.deleteCustomer(customer.id!);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
