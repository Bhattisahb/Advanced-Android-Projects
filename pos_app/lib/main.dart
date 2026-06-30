/// Main Entry Point
/// Sets up providers and configures routing
/// Handles authentication state and navigation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/core/services/auth_service.dart';
import 'package:pos_app/core/services/transaction_service.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/repositories/pos_repository.dart';
import 'package:pos_app/data/repositories/product_repository.dart';
import 'package:pos_app/data/repositories/inventory_repository.dart';

import 'package:pos_app/ui/auth/login_screen.dart';
import 'package:pos_app/ui/auth/signup_screen.dart';
import 'package:pos_app/ui/shared/home_screen.dart';
import 'package:pos_app/ui/products/product_list_screen.dart';
import 'package:pos_app/ui/products/product_form_screen.dart';
import 'package:pos_app/ui/inventory/inventory_screen.dart';
import 'package:pos_app/ui/pos/pos_screen.dart';
import 'package:pos_app/ui/customers/customer_management_screen.dart';
import 'package:pos_app/ui/reports/reports_screen.dart';
import 'package:pos_app/ui/backup/backup_sync_screen.dart';
import 'package:pos_app/ui/transactions/transaction_history_screen.dart';

void main() {
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Service
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // Transaction Service (for real-time transaction updates)
        ChangeNotifierProvider<TransactionService>(
          create: (_) => TransactionService(),
        ),
        // Product Repository
        Provider<ProductRepository>(
          create: (_) => ProductRepository(),
        ),
        // Inventory Repository
        Provider<InventoryRepository>(
          create: (_) => InventoryRepository(),
        ),
        // POS Repository (for cart and checkout)
        ChangeNotifierProvider<POSRepository>(
          create: (_) => POSRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart POS - Inventory Management',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.DEFAULT_BORDER_RADIUS,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.DEFAULT_BORDER_RADIUS,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
        home: const _AuthWrapper(),
        routes: {
          AppConstants.ROUTE_LOGIN: (_) => const LoginScreen(),
          AppConstants.ROUTE_SIGNUP: (_) => const SignupScreen(),
          AppConstants.ROUTE_HOME: (_) => const HomeScreen(),
          AppConstants.ROUTE_PRODUCTS: (_) => const ProductListScreen(),
          AppConstants.ROUTE_PRODUCT_FORM: (context) {
            final product = ModalRoute.of(context)?.settings.arguments as Product?;
            return ProductFormScreen(product: product);
          },
          AppConstants.ROUTE_INVENTORY: (_) => const InventoryScreen(),
          AppConstants.ROUTE_POS: (_) => const POSScreen(),
          AppConstants.ROUTE_CUSTOMERS: (_) => const CustomerManagementScreen(),
          AppConstants.ROUTE_REPORTS: (_) => const ReportsScreen(),
          AppConstants.ROUTE_TRANSACTIONS: (_) => const TransactionHistoryScreen(),
          AppConstants.ROUTE_BACKUP: (_) => const BackupSyncScreen(),
        },
      ),
    );
  }
}

/// Authentication Wrapper
/// Routes users to login or home based on authentication state
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        // Waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Smart POS',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}

