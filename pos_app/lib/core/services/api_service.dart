/// REST API Service
/// Handles all HTTP communication with backend
/// Backend-agnostic: can work with any REST API
/// Includes retry logic and error handling
/// JSON serialization for all requests/responses

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_app/data/models/sale_model.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/models/customer_model.dart';

class ApiService {
  // Configure these for your backend
  static const String BASE_URL = 'https://api.example.com';
  static const String SALES_ENDPOINT = '/api/sales';
  static const String PRODUCTS_ENDPOINT = '/api/products';
  static const String CUSTOMERS_ENDPOINT = '/api/customers';
  static const String BACKUPS_ENDPOINT = '/api/backups';

  static const int RETRY_COUNT = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 2);

  final http.Client _client = http.Client();

  /// Sync sales to backend
  /// Sends all unsynced sales and marks them as synced
  Future<List<int>> syncSales(List<Sale> sales) async {
    final syncedIds = <int>[];

    for (final sale in sales) {
      try {
        final response = await _makeRequest(
          method: 'POST',
          endpoint: SALES_ENDPOINT,
          body: {
            'id': sale.id,
            'customerId': sale.customerId,
            'subtotal': sale.subtotal,
            'discountAmount': sale.discountAmount,
            'discountPercentage': sale.discountPercentage,
            'taxAmount': sale.taxAmount,
            'totalAmount': sale.totalAmount,
            'status': sale.status,
            'paymentMethod': sale.paymentMethod,
            'createdAt': sale.createdAt.toIso8601String(),
            'updatedAt': sale.updatedAt?.toIso8601String(),
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          syncedIds.add(sale.id!);
        }
      } catch (e) {
        print('Error syncing sale ${sale.id}: $e');
        // Continue with next sale
      }
    }

    return syncedIds;
  }

  /// Sync products to backend
  Future<List<int>> syncProducts(List<Product> products) async {
    final syncedIds = <int>[];

    for (final product in products) {
      try {
        final response = await _makeRequest(
          method: 'POST',
          endpoint: PRODUCTS_ENDPOINT,
          body: {
            'id': product.id,
            'name': product.name,
            'sku': product.sku,
            'price': product.price,
            'cost': product.cost,
            'category': product.category,
            'stockQuantity': product.stockQuantity,
            'createdAt': product.createdAt.toIso8601String(),
            'updatedAt': product.updatedAt?.toIso8601String(),
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          syncedIds.add(product.id!);
        }
      } catch (e) {
        print('Error syncing product ${product.id}: $e');
      }
    }

    return syncedIds;
  }

  /// Sync customers to backend
  Future<List<int>> syncCustomers(List<Customer> customers) async {
    final syncedIds = <int>[];

    for (final customer in customers) {
      try {
        final response = await _makeRequest(
          method: 'POST',
          endpoint: CUSTOMERS_ENDPOINT,
          body: {
            'id': customer.id,
            'name': customer.name,
            'email': customer.email,
            'phone': customer.phone,
            'type': customer.type,
            'createdAt': customer.createdAt.toIso8601String(),
            'updatedAt': customer.updatedAt?.toIso8601String(),
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          syncedIds.add(customer.id!);
        }
      } catch (e) {
        print('Error syncing customer ${customer.id}: $e');
      }
    }

    return syncedIds;
  }

  /// Upload backup file to cloud storage
  /// Returns the backup file ID on success
  Future<String> uploadBackup({
    required String fileName,
    required String fileContent,
  }) async {
    try {
      print('🔄 Attempting cloud backup upload to: $BASE_URL$BACKUPS_ENDPOINT');
      
      if (BASE_URL.contains('example.com')) {
        throw Exception('Cloud API not configured. Please set BASE_URL in ApiService');
      }

      final response = await _makeRequest(
        method: 'POST',
        endpoint: BACKUPS_ENDPOINT,
        body: {
          'fileName': fileName,
          'content': fileContent,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✓ Cloud backup uploaded successfully');
        return data['id'] ?? fileName;
      } else {
        throw Exception('Failed to upload backup: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('✗ Backup upload error: $e');
      throw Exception('Backup upload error: $e');
    }
  }

  /// Download backup file from cloud storage
  Future<String> downloadBackup(String backupId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '$BACKUPS_ENDPOINT/$backupId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'] ?? '';
      } else {
        throw Exception('Failed to download backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Backup download error: $e');
    }
  }

  /// List all backups
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: BACKUPS_ENDPOINT,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['backups'] ?? []);
      } else {
        throw Exception('Failed to list backups: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('List backups error: $e');
    }
  }

  /// Generic HTTP request method with retry logic
  Future<http.Response> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    int attempt = 0;

    while (attempt < RETRY_COUNT) {
      try {
        final uri = Uri.parse('$BASE_URL$endpoint');

        http.Response response;

        if (method == 'GET') {
          response = await _client.get(uri);
        } else if (method == 'POST') {
          response = await _client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          );
        } else if (method == 'PUT') {
          response = await _client.put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          );
        } else {
          throw Exception('Unsupported HTTP method: $method');
        }

        return response;
      } catch (e) {
        attempt++;

        if (attempt >= RETRY_COUNT) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(RETRY_DELAY);
      }
    }

    throw Exception('Max retries exceeded');
  }
}
