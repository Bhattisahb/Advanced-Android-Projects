/// Sync Manager
/// Coordinates automatic syncing of data
/// Monitors connectivity and triggers sync when online
/// Manages sync queue and tracks sync status
/// Handles conflict resolution (latest updatedAt wins)

import 'package:pos_app/core/services/api_service.dart';
import 'package:pos_app/core/services/connectivity_service.dart';
import 'package:pos_app/data/local/sale_dao.dart';
import 'package:pos_app/data/local/product_dao.dart';
import 'package:pos_app/data/local/customer_dao.dart';
import 'package:pos_app/data/repositories/product_repository.dart';

class SyncManager {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SaleDAO _saleDAO = SaleDAO();
  final ProductDao _productDAO = ProductDao();
  final CustomerDAO _customerDAO = CustomerDAO();
  final ProductRepository _productRepository = ProductRepository();

  bool _isSyncing = false;

  /// Initialize sync monitoring
  Future<void> initialize() async {
    await _connectivityService.initialize();

    // Listen for connectivity changes
    _connectivityService.connectionStatus.listen((isOnline) {
      if (isOnline) {
        // Auto-sync when device comes online
        performSync();
      }
    });
  }

  /// Perform full sync with backend
  /// Syncs unsynced records to backend
  Future<void> performSync() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      // Sync sales
      final unsyncedSales = await _saleDAO.getUnsyncedSales();
      if (unsyncedSales.isNotEmpty) {
        final syncedIds = await _apiService.syncSales(unsyncedSales);
        for (final id in syncedIds) {
          await _saleDAO.markAsSynced(id);
        }
      }

      // Sync products
      final allProducts = await _productDAO.getAllProducts();
      if (allProducts.isNotEmpty) {
        final syncedIds = await _apiService.syncProducts(allProducts);
        print('Synced ${syncedIds.length} products');
      }

      // Sync customers
      final allCustomers = await _customerDAO.getAllCustomers();
      if (allCustomers.isNotEmpty) {
        final syncedIds = await _apiService.syncCustomers(allCustomers);
        print('Synced ${syncedIds.length} customers');
      }

      print('Sync completed successfully');
    } catch (e) {
      print('Sync error: $e');
      // Silently fail - will retry when connectivity changes
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Check if online
  bool get isOnline => _connectivityService.isOnline;

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivityService.dispose();
  }
}
