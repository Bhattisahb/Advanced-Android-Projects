import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/consts/contss.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/home_screen_tiles_provider.dart';
import 'package:grocery_app/providers/product_ratings_provider.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/route_paths.dart';
import 'package:grocery_app/screens/auth/verify_email_screen.dart';
import 'package:grocery_app/services/auth_gate_service.dart';
import 'package:grocery_app/services/guest_session.dart';
import 'package:grocery_app/services/push_notification_service.dart';
import 'package:grocery_app/screens/btm_bar.dart';
import 'package:provider/provider.dart';

import 'providers/products_provider.dart';

class FetchScreen extends StatefulWidget {
  const FetchScreen({super.key, this.allowGuest = false});

  final bool allowGuest;

  @override
  State<FetchScreen> createState() => _FetchScreenState();
}

class _FetchScreenState extends State<FetchScreen> {
  List<String> images = Constss.authImagesPaths;
  @override
  void initState() {
    super.initState();
    images.shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final ratingsProvider =
        Provider.of<ProductRatingsProvider>(context, listen: false);
    final homeTiles =
        Provider.of<HomeScreenTilesProvider>(context, listen: false);
    final gate = await AuthGateService.resolve();

    if (gate.status == AuthGateStatus.guest) {
      if (!widget.allowGuest && !GuestSession.isEnabled) {
        cartProvider.clearLocalCart();
        wishlistProvider.clearLocalWishlist();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(RoutePaths.login);
        return;
      }
      cartProvider.clearLocalCart();
      wishlistProvider.clearLocalWishlist();
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
      await productsProvider.fetchProducts();
      try {
        await homeTiles.fetchTiles();
      } catch (_) {}
      try {
        await ratingsProvider.refresh();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            'Ratings aggregate skipped: $e\n$st '
            '(needs Firestore read on product_reviews).',
          );
        }
      }
      try {
        if (gate.canUsePrivateData) {
          await cartProvider.fetchCart();
        }
      } on FirebaseException catch (e) {
        if (kDebugMode) {
          debugPrint(
            'Cart load skipped (${e.code}): ${e.message}. '
            'Rules must allow verified read on users/${gate.user?.uid} '
            '(field userCart).',
          );
        }
      }
      try {
        if (gate.canUsePrivateData) {
          await wishlistProvider.fetchWishlist();
        }
      } on FirebaseException catch (e) {
        if (kDebugMode) {
          debugPrint(
            'Wishlist load skipped (${e.code}): ${e.message}. '
            'Rules must allow verified read on users/${gate.user?.uid} '
            '(wishlist fields).',
          );
        }
      }
      try {
        if (gate.canUsePrivateData) {
          final u = authInstance.currentUser;
          if (u != null) {
            await PushNotificationService.syncSession(
              user: u,
              isCustomerApp: true,
              subscribeAdminTopic: false,
            );
          }
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Push notifications setup skipped: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Load error: $e\n$st');
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (ctx) => const BottomBarScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            images[0],
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
          )
        ],
      ),
    );
  }
}
