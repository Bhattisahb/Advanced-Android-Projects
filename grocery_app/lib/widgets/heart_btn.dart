import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/auth_gate_service.dart';
import '../services/global_methods.dart';
import '../services/utils.dart';

class HeartBTN extends StatefulWidget {
  const HeartBTN({Key? key, required this.productId, this.isInWishlist = false})
      : super(key: key);
  final String productId;
  final bool? isInWishlist;

  @override
  State<HeartBTN> createState() => _HeartBTNState();
}

class _HeartBTNState extends State<HeartBTN> {
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductsProvider>(context);
    final getCurrProduct = productProvider.findProdById(widget.productId);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final Color color = Utils(context).color;
    return GestureDetector(
      onTap: () async {
        setState(() {
          loading = true;
        });
        try {
          final user = await AuthGateService.requireVerifiedUser(
            context,
            message: 'Sign in with a verified account to manage your wishlist.',
          );
          if (user == null) return;
          if (!context.mounted) return;
          if (widget.isInWishlist == false && widget.isInWishlist != null) {
            await GlobalMethods.addToWishlist(
                productId: widget.productId, context: context);
          } else {
            await wishlistProvider.removeOneItem(
                wishlistId:
                    wishlistProvider.getWishlistItems[getCurrProduct.id]!.id,
                productId: widget.productId);
          }
          await wishlistProvider.fetchWishlist();
          if (!mounted) return;
          setState(() {
            loading = false;
          });
        } catch (error) {
          if (!context.mounted) return;
          GlobalMethods.errorDialog(subtitle: '$error', context: context);
        } finally {
          if (mounted) {
            setState(() {
              loading = false;
            });
          }
        }
      },
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                  height: 15, width: 15, child: CircularProgressIndicator()),
            )
          : Icon(
              widget.isInWishlist != null && widget.isInWishlist == true
                  ? IconlyBold.heart
                  : IconlyLight.heart,
              size: 22,
              color: widget.isInWishlist != null && widget.isInWishlist == true
                  ? Colors.red
                  : color,
            ),
    );
  }
}
