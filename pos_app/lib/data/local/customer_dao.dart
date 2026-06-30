/// Customer DAO
/// Data Access Object for customer CRUD operations
/// Handles all database queries for customers

import 'package:sqflite/sqflite.dart';
import 'package:pos_app/data/local/database_helper.dart';
import 'package:pos_app/data/models/customer_model.dart';

class CustomerDAO {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    final results = await db.query('customers', orderBy: 'name ASC');
    return results.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Customer.fromMap(results.first);
  }

  /// Get all registered customers
  Future<List<Customer>> getRegisteredCustomers() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'customers',
      where: "type = ?",
      whereArgs: ['REGISTERED'],
      orderBy: 'name ASC',
    );
    return results.map((map) => Customer.fromMap(map)).toList();
  }

  /// Search customers by name or phone
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'customers',
      where: "name LIKE ? OR phone LIKE ?",
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return results.map((map) => Customer.fromMap(map)).toList();
  }

  /// Add new customer
  Future<Customer> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final id = await db.insert('customers', {
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'type': customer.type,
      'createdAt': customer.createdAt.toIso8601String(),
      'updatedAt': customer.updatedAt?.toIso8601String(),
    });
    return customer.copyWith(id: id);
  }

  /// Update customer
  Future<void> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      {
        'name': customer.name,
        'email': customer.email,
        'phone': customer.phone,
        'type': customer.type,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete customer
  Future<void> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
