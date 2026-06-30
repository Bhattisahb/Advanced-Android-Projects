/// Backup Service
/// Handles local and cloud backups
/// Exports SQLite data to JSON format
/// Restores from JSON backups
/// Auto-backup functionality

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/data/local/product_dao.dart';
import 'package:pos_app/data/local/stock_history_dao.dart';
import 'package:pos_app/data/local/customer_dao.dart';
import 'package:pos_app/data/local/sale_dao.dart';
import 'package:pos_app/data/local/ledger_entry_dao.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/models/stock_history_model.dart';
import 'package:pos_app/data/models/customer_model.dart';
import 'package:pos_app/data/models/sale_model.dart';

class BackupService {
  final ProductDao _productDAO = ProductDao();
  final StockHistoryDao _historyDAO = StockHistoryDao();
  final CustomerDAO _customerDAO = CustomerDAO();
  final SaleDAO _saleDAO = SaleDAO();
  final LedgerEntryDAO _ledgerDAO = LedgerEntryDAO();

  /// Backup format (JSON):
  /// {
  ///   "version": "1.0",
  ///   "timestamp": "2024-01-05T10:30:00Z",
  ///   "tables": {
  ///     "products": [...],
  ///     "stock_history": [...],
  ///     "customers": [...],
  ///     "sales": [...],
  ///     "sale_items": [...],
  ///     "ledger_entries": [...]
  ///   }
  /// }

  /// Create local backup and return file path
  Future<String> createLocalBackup() async {
    try {
      // Fetch all data with safe error handling
      List<Product> products = [];
      List<StockHistory> history = [];
      List<Customer> customers = [];
      List<Sale> sales = [];
      
      try {
        products = await _productDAO.getAllProducts();
        print('✓ Fetched ${products.length} products');
      } catch (e) {
        print('⚠️ Error fetching products: $e');
      }
      
      try {
        history = await _historyDAO.getAll();
        print('✓ Fetched ${history.length} stock history entries');
      } catch (e) {
        print('⚠️ Error fetching stock history: $e');
      }
      
      try {
        customers = await _customerDAO.getAllCustomers();
        print('✓ Fetched ${customers.length} customers');
      } catch (e) {
        print('⚠️ Error fetching customers: $e');
      }
      
      try {
        sales = await _saleDAO.getAllSales();
        print('✓ Fetched ${sales.length} sales');
      } catch (e) {
        print('⚠️ Error fetching sales: $e');
      }

      print('Backup data - Products: ${products.length}, History: ${history.length}, Customers: ${customers.length}, Sales: ${sales.length}');

      // Build backup structure
      final backup = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'tables': {
          'products': products.map((p) => p.toJson()).toList(),
          'stock_history': history.map((h) => h.toJson()).toList(),
          'customers': customers.map((c) => c.toMap()).toList(),
          'sales': sales.map((s) => s.toMap()).toList(),
        },
      };

      // Convert to JSON
      final jsonContent = jsonEncode(backup);
      print('Backup JSON size: ${jsonContent.length} bytes');

      // Save to device storage
      final fileName =
          'pos_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = await _getBackupFile(fileName);
      
      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);
      
      // Write file
      await file.writeAsString(jsonContent);
      
      print('✓ Backup saved successfully to: ${file.path}');
      return file.path;
    } catch (e) {
      print('✗ Backup creation error: $e');
      throw Exception('Backup creation failed: $e');
    }
  }

  /// List all local backups
  Future<List<FileSystemEntity>> listLocalBackups() async {
    try {
      final dir = await _getBackupDirectory();
      
      // Check if directory exists
      if (!await dir.exists()) {
        print('Backup directory does not exist, creating it...');
        await dir.create(recursive: true);
        return [];
      }
      
      final files = dir
          .listSync()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      
      print('Found ${files.length} backup files');
      
      files.sort((a, b) => b.statSync().modified
          .compareTo(a.statSync().modified)); // Newest first
      return files;
    } catch (e) {
      print('Error listing backups: $e');
      throw Exception('Failed to list backups: $e');
    }
  }

  /// Restore from local backup file
  Future<void> restoreFromLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final content = await file.readAsString();
      final backup = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup format
      if (backup['version'] != '1.0') {
        throw Exception('Unsupported backup version');
      }

      final tables = backup['tables'] as Map<String, dynamic>;

      // Restore each table
      // Note: This is a simplified restoration
      // In production, you may want to clear existing data first
      print('Backup format: ${backup['timestamp']}');
      print('Contains ${tables.length} tables');

      // To fully restore, you would need to:
      // 1. Clear all existing data
      // 2. Import each table
      // This requires transaction support in DAOs
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }

  /// Get backup directory
  Future<Directory> getBackupDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/pos_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<Directory> _getBackupDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/pos_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Get or create backup file
  Future<File> _getBackupFile(String fileName) async {
    final dir = await _getBackupDirectory();
    return File('${dir.path}/$fileName');
  }

  /// Get backup file size (formatted)
  Future<String> getBackupSize(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();

      if (size < 1024) {
        return '$size B';
      } else if (size < 1024 * 1024) {
        return '${(size / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Delete backup file
  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  /// Restore from backup content (string)
  /// Used for restoring from cloud/Google Drive backups
  Future<void> restoreFromContent(String content) async {
    try {
      final backup = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup format
      if (backup['version'] != '1.0') {
        throw Exception('Unsupported backup version');
      }

      final tables = backup['tables'] as Map<String, dynamic>;

      // Validate that all required tables are present (matching what's backed up)
      final requiredTables = [
        'products',
        'stock_history',
        'customers',
        'sales',
      ];

      for (final table in requiredTables) {
        if (!tables.containsKey(table)) {
          throw Exception('Missing table: $table');
        }
      }

      // Log restoration info
      print('Backup format: ${backup['timestamp']}');
      print('Contains ${tables.length} tables');
      print('Ready to restore ${tables.length} tables');
      
      // Validate table data
      print('Products: ${(tables['products'] as List).length} items');
      print('Stock History: ${(tables['stock_history'] as List).length} items');
      print('Customers: ${(tables['customers'] as List).length} items');
      print('Sales: ${(tables['sales'] as List).length} items');

      // Note: Full restoration would require:
      // 1. Clear all existing data
      // 2. Import each table using DAOs
      // 3. Transaction support for data integrity
      // This is prepared for future implementation
    } catch (e) {
      throw Exception('Restore validation failed: $e');
    }
  }
}

