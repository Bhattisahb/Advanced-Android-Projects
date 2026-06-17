import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:grocery_app/consts/contss.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/providers/home_screen_tiles_provider.dart';
import 'package:grocery_app/providers/product_ratings_provider.dart';
import 'package:grocery_app/screens/auth/verify_email_screen.dart';
import 'package:grocery_app/services/auth_gate_service.dart';
import 'package:grocery_app/route_paths.dart';
import 'package:grocery_app/screens/admin/admin_dashboard_screen.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/push_notification_service.dart';
import 'package:provider/provider.dart';

import 'providers/products_provider.dart';

/// Splash gate for the admin-only app: login → admin check → dashboard.
class AdminFetchScreen extends StatefulWidget {
  const AdminFetchScreen({super.key});

  @override
  State<AdminFetchScreen> createState() => _AdminFetchScreenState();
}

class _AdminFetchScreenState extends State<AdminFetchScreen> {
  final List<String> _images = Constss.authImagesPaths;

  @override
  void initState() {
    super.initState();
    _images.shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final ratingsProvider =
        Provider.of<ProductRatingsProvider>(context, listen: false);
    final homeTiles =
        Provider.of<HomeScreenTilesProvider>(context, listen: false);
    final categories =
        Provider.of<CategoriesProvider>(context, listen: false);
    final gate = await AuthGateService.resolve();

    if (gate.status == AuthGateStatus.guest) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RoutePaths.login);
      return;
    }

    if (gate.status == AuthGateStatus.needsEmailVerification) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const VerifyEmailScreen(),
        ),
      );
      return;
    }

    try {
      await productsProvider.fetchProducts(includeHiddenFromCatalog: true);
      try {
        await homeTiles.fetchTiles();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Home tiles prefetch skipped: $e\n$st');
        }
      }
      try {
        await categories.fetchCategories();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Categories prefetch skipped: $e\n$st');
        }
      }
      try {
        await ratingsProvider.refresh();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Ratings aggregate skipped: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Admin load error: $e\n$st');
      }
    }

    if (!mounted) return;

    final isAdmin = await const AdminService().isCurrentUserAdmin();
    if (!mounted) return;

    if (!isAdmin) {
      await authInstance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This account is not an admin.'),
        ),
      );
      Navigator.of(context).pushReplacementNamed(RoutePaths.login);
      return;
    }

    final user = authInstance.currentUser;
    if (user != null) {
      try {
        await PushNotificationService.syncSession(
          user: user,
          isCustomerApp: false,
          subscribeAdminTopic: true,
        );
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Push notifications setup skipped: $e\n$st');
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            _images[0],
            fit: BoxFit.cover,
            height: double.infinity,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.7),
          ),
          const Center(
            child: SpinKitFadingFour(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
