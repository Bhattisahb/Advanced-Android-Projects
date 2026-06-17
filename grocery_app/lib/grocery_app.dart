import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/admin_fetch_screen.dart';
import 'package:grocery_app/app_navigator.dart';
import 'package:grocery_app/app_scope.dart';
import 'package:grocery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_app/providers/admin_orders_provider.dart';
import 'package:grocery_app/providers/dark_theme_provider.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/providers/product_ratings_provider.dart';
import 'package:grocery_app/providers/home_screen_tiles_provider.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/viewed_prod_provider.dart';
import 'package:grocery_app/screens/admin/admin_home_tiles_screen.dart';
import 'package:grocery_app/screens/admin/admin_categories_screen.dart';
import 'package:grocery_app/screens/admin/admin_dashboard_screen.dart';
import 'package:grocery_app/screens/admin/admin_insights_screen.dart';
import 'package:grocery_app/screens/admin/admin_orders_screen.dart';
import 'package:grocery_app/screens/admin/admin_product_edit_screen.dart';
import 'package:grocery_app/screens/admin/admin_products_screen.dart';
import 'package:grocery_app/screens/admin/admin_users_screen.dart';
import 'package:grocery_app/screens/viewed_recently/viewed_recently.dart';
import 'package:provider/provider.dart';

import 'consts/theme_data.dart';
import 'fetch_screen.dart';
import 'inner_screens/cat_screen.dart';
import 'inner_screens/feeds_screen.dart';
import 'inner_screens/most_rated_screen.dart';
import 'inner_screens/product_details.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/auth/forget_pass.dart';
import 'screens/auth/login.dart';
import 'screens/auth/register.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/home_shortcut_products_screen.dart';
import 'screens/store_search_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'services/system_local_notifications_service.dart';
import 'widgets/global_pull_to_refresh_host.dart';

Future<void> bootstrap({required bool customerApp}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemLocalNotificationsService.initialize(rootNavigatorKey);
  runApp(GroceryMaterialApp(isCustomerApp: customerApp));
}

class GroceryMaterialApp extends StatefulWidget {
  const GroceryMaterialApp({super.key, required this.isCustomerApp});

  final bool isCustomerApp;

  @override
  State<GroceryMaterialApp> createState() => _GroceryMaterialAppState();
}

class _GroceryMaterialAppState extends State<GroceryMaterialApp> {
  final DarkThemeProvider _themeChangeProvider = DarkThemeProvider();

  Future<void> _getCurrentAppTheme() async {
    _themeChangeProvider.setDarkTheme =
        await _themeChangeProvider.darkThemePrefs.getTheme();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentAppTheme();
  }

  final Future<FirebaseApp> _firebaseInitialization = Firebase.initializeApp();

  Map<String, WidgetBuilder> _routes() {
    final authAndAdmin = <String, WidgetBuilder>{
      LoginScreen.routeName: (ctx) => const LoginScreen(),
      RegisterScreen.routeName: (ctx) => const RegisterScreen(),
      VerifyEmailScreen.routeName: (ctx) => const VerifyEmailScreen(),
      ForgetPasswordScreen.routeName: (ctx) => const ForgetPasswordScreen(),
      AdminHomeTilesScreen.routeName: (ctx) => const AdminHomeTilesScreen(),
      AdminCategoriesScreen.routeName: (ctx) => const AdminCategoriesScreen(),
      AdminProductsScreen.routeName: (ctx) => const AdminProductsScreen(),
      AdminProductEditScreen.routeName: (ctx) => const AdminProductEditScreen(),
      AdminDashboardScreen.routeName: (ctx) => const AdminDashboardScreen(),
      AdminInsightsScreen.routeName: (ctx) => const AdminInsightsScreen(),
      AdminOrdersScreen.routeName: (ctx) {
        final arg = ModalRoute.of(ctx)?.settings.arguments;
        final uid = arg is String ? arg : null;
        return AdminOrdersScreen(filterUserId: uid);
      },
      AdminUsersScreen.routeName: (ctx) => const AdminUsersScreen(),
    };

    /// Storefront routes (browse, shortcut grids, product detail). Registered for
    /// both APKs so standalone admin matches customer-app navigation surface.
    final storefront = <String, WidgetBuilder>{
      OnSaleScreen.routeName: (ctx) => const OnSaleScreen(),
      FeedsScreen.routeName: (ctx) => const FeedsScreen(),
      MostRatedScreen.routeName: (ctx) => const MostRatedScreen(),
      ProductDetails.routeName: (ctx) => const ProductDetails(),
      WishlistScreen.routeName: (ctx) => const WishlistScreen(),
      OrdersScreen.routeName: (ctx) => const OrdersScreen(),
      ViewedRecentlyScreen.routeName: (ctx) => const ViewedRecentlyScreen(),
      CategoryScreen.routeName: (ctx) => const CategoryScreen(),
      HomeShortcutProductsScreen.routeName: (ctx) =>
          const HomeShortcutProductsScreen(),
      StoreSearchScreen.routeName: (ctx) => const StoreSearchScreen(),
    };

    return {...authAndAdmin, ...storefront};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInitialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Firebase error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        return AppScope(
          isCustomerApp: widget.isCustomerApp,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => _themeChangeProvider),
              ChangeNotifierProvider(create: (_) => ProductsProvider()),
              ChangeNotifierProvider(create: (_) => CategoriesProvider()),
              ChangeNotifierProvider(create: (_) => HomeScreenTilesProvider()),
              ChangeNotifierProvider(create: (_) => ProductRatingsProvider()),
              ChangeNotifierProvider(create: (_) => CartProvider()),
              ChangeNotifierProvider(create: (_) => WishlistProvider()),
              ChangeNotifierProvider(create: (_) => ViewedProdProvider()),
              ChangeNotifierProvider(create: (_) => OrdersProvider()),
              ChangeNotifierProvider(create: (_) => AdminOrdersProvider()),
            ],
            child: Consumer<DarkThemeProvider>(
              builder: (context, themeProvider, child) {
                return MaterialApp(
                  navigatorKey: rootNavigatorKey,
                  debugShowCheckedModeBanner: false,
                  title: widget.isCustomerApp ? 'Grocery Store' : 'Grocery Admin',
                  theme:
                      Styles.themeData(themeProvider.getDarkTheme, context),
                  builder: (context, child) => _PendingNotificationLaunchHook(
                    child: GlobalPullToRefreshHost(child: child),
                  ),
                  home: widget.isCustomerApp
                      ? const FetchScreen()
                      : const AdminFetchScreen(),
                  routes: _routes(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Handles tap navigation when the app was **cold-started** from a tray notification.
class _PendingNotificationLaunchHook extends StatefulWidget {
  const _PendingNotificationLaunchHook({required this.child});

  final Widget? child;

  @override
  State<_PendingNotificationLaunchHook> createState() =>
      _PendingNotificationLaunchHookState();
}

class _PendingNotificationLaunchHookState
    extends State<_PendingNotificationLaunchHook> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemLocalNotificationsService.consumePendingLaunchNavigation();
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.child ?? const SizedBox.shrink();
}
