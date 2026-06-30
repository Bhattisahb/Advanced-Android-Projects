/// Ledger Entry DAO
/// Data Access Object for ledger operations
/// Handles tracking customer credits and debits

import 'package:sqflite/sqflite.dart';
import 'package:pos_app/data/local/database_helper.dart';
import 'package:pos_app/data/models/ledger_entry_model.dart';

class LedgerEntryDAO {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Add ledger entry
  Future<int> addEntry(LedgerEntry entry) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert(
        'ledger_entries',
        entry.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error adding ledger entry: $e');
      rethrow;
    }
  }

  /// Get all entries for a customer
  Future<List<LedgerEntry>> getCustomerEntries(int customerId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'ledger_entries',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => LedgerEntry.fromMap(map)).toList();
  }

  /// Get outstanding balance for a customer
  /// DEBIT = amount owed, CREDIT = amount paid
  /// Outstanding = sum(DEBIT) - sum(CREDIT)
  Future<double> getOutstandingBalance(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'DEBIT' THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type = 'CREDIT' THEN amount ELSE 0 END), 0) as balance
      FROM ledger_entries
      WHERE customerId = ?
      ''',
      [customerId],
    );

    final balance = result.first['balance'];
    return balance == null ? 0.0 : (balance as num).toDouble();
  }

  /// Get payment history for a customer
  Future<List<LedgerEntry>> getPaymentHistory(int customerId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'ledger_entries',
      where: 'customerId = ? AND type = ?',
      whereArgs: [customerId, 'CREDIT'],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => LedgerEntry.fromMap(map)).toList();
  }

  /// Get sale entries for a customer
  Future<List<LedgerEntry>> getSaleEntries(int customerId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'ledger_entries',
      where: 'customerId = ? AND type = ?',
      whereArgs: [customerId, 'DEBIT'],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => LedgerEntry.fromMap(map)).toList();
  }

  /// Get total credit balance for a customer
  Future<double> getTotalCredit(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM ledger_entries
      WHERE customerId = ? AND type = 'CREDIT'
      ''',
      [customerId],
    );

    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  /// Delete ledger entry
  Future<void> deleteEntry(int id) async {
    final db = await _dbHelper.database;
    await db.delete('ledger_entries', where: 'id = ?', whereArgs: [id]);
  }
}
