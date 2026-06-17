import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/inner_screens/product_details.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:provider/provider.dart';

/// Horizontal card used on home (featured / category strips).
class HomeFeatureTile extends StatelessWidget {
  const HomeFeatureTile({
    Key? key,
    required this.width,
    this.averageRating,
    this.reviewCount,
  }) : super(key: key);

  final double width;

  /// Shown on the home “most rated” strip when set (e.g. from [ProductRatingsProvider]).
  final double? averageRating;
  final int? reviewCount;

  static const Color _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final height = width * 1.15;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              ProductDetails.routeName,
              arguments: productModel.id,
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkProductImage(
                    imageUrl: productModel.imageUrl,
                    boxFit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: height * 0.42,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (productModel.isOnSale)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Sale',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          final User? user = authInstance.currentUser;
                          if (user == null) {
                            GlobalMethods.errorDialog(
                              subtitle: 'Please sign in to add items',
                              context: context,
                            );
                            return;
                          }
                          await GlobalMethods.addToCart(
                            productId: productModel.id,
                            quantity: 1,
                            context: context,
                          );
                          await cartProvider.fetchCart();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            IconlyBold.plus,
                            color: _accent,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          productModel.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (averageRating != null && averageRating! > 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: _accent,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${averageRating!.toStringAsFixed(1)}'
                                '${reviewCount != null && reviewCount! > 0 ? ' ($reviewCount)' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Text(
                              formatPkr(
                                  productModel.isOnSale
                                      ? productModel.salePrice
                                      : productModel.price),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (productModel.isOnSale) ...[
                              const SizedBox(width: 6),
                              Text(
                                formatPkr(productModel.price),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
