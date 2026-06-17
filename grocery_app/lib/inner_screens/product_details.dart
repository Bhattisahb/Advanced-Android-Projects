import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_app/widgets/heart_btn.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/viewed_prod_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/auth_gate_service.dart';
import '../services/customer_flow_refresh.dart';
import '../services/manual_checkout_service.dart';
import '../widgets/manual_payment_sheet.dart';
import '../services/global_methods.dart';
import '../services/utils.dart';
import '../widgets/network_product_image.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/text_widget.dart';

class ProductDetails extends StatefulWidget {
  static const routeName = '/ProductDetails';

  const ProductDetails({Key? key}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final _quantityTextController = TextEditingController(text: '1');

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _quantityTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    final Color color = Utils(context).color;

    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final productId = args is String ? args : null;
    final productProvider = Provider.of<ProductsProvider>(context);

    if (productId == null || productId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                Navigator.canPop(context) ? Navigator.pop(context) : null,
            child: Icon(IconlyLight.arrowLeft2, color: color, size: 24),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TextWidget(
              text:
                  'Missing product reference. Go back and open the item again.',
              color: color,
              textSize: 18,
            ),
          ),
        ),
      );
    }

    final getCurrProduct = productProvider.findProdByIdOrNull(productId);
    if (getCurrProduct == null) {
      return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                Navigator.canPop(context) ? Navigator.pop(context) : null,
            child: Icon(IconlyLight.arrowLeft2, color: color, size: 24),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TextWidget(
              text:
                  'This product is no longer in the catalog (id: $productId).',
              color: color,
              textSize: 18,
            ),
          ),
        ),
      );
    }

    double usedPrice = getCurrProduct.isOnSale
        ? getCurrProduct.salePrice
        : getCurrProduct.price;
    double totalPrice = usedPrice * int.parse(_quantityTextController.text);
    bool? _isInCart = cartProvider.getCartItems.containsKey(getCurrProduct.id);

    bool? _isInWishlist =
        wishlistProvider.getWishlistItems.containsKey(getCurrProduct.id);

    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        viewedProdProvider.addProductToHistory(productId: productId);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
            leading: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  Navigator.canPop(context) ? Navigator.pop(context) : null,
              child: Icon(
                IconlyLight.arrowLeft2,
                color: color,
                size: 24,
              ),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        body: Column(children: [
          Flexible(
            flex: 2,
            child: NetworkProductImage(
              imageUrl: getCurrProduct.imageUrl,
              width: size.width,
              height: size.height * 0.34,
              boxFit: BoxFit.contain,
            ),
          ),
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 20, left: 30, right: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: TextWidget(
                              text: getCurrProduct.title,
                              color: color,
                              textSize: 25,
                              isTitle: true,
                            ),
                          ),
                          HeartBTN(
                            productId: getCurrProduct.id,
                            isInWishlist: _isInWishlist,
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 20, left: 30, right: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextWidget(
                            text: formatPkr(usedPrice),
                            color: Colors.green,
                            textSize: 22,
                            isTitle: true,
                          ),
                          TextWidget(
                            text: getCurrProduct.isPiece ? '/Piece' : '/Kg',
                            color: color,
                            textSize: 12,
                            isTitle: false,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Visibility(
                            visible: getCurrProduct.isOnSale ? true : false,
                            child: Text(
                              formatPkr(getCurrProduct.price),
                              style: TextStyle(
                                  fontSize: 15,
                                  color: color,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                                color: const Color.fromRGBO(63, 200, 101, 1),
                                borderRadius: BorderRadius.circular(5)),
                            child: TextWidget(
                              text: 'Free delivery',
                              color: Colors.white,
                              textSize: 20,
                              isTitle: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 16, left: 30, right: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'About this item',
                            color: color,
                            textSize: 16,
                            isTitle: true,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getCurrProduct.description,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.82),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        quantityControl(
                          fct: () {
                            if (_quantityTextController.text == '1') {
                              return;
                            } else {
                              setState(() {
                                _quantityTextController.text =
                                    (int.parse(_quantityTextController.text) -
                                            1)
                                        .toString();
                              });
                            }
                          },
                          icon: CupertinoIcons.minus,
                          color: Colors.red,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Flexible(
                          flex: 1,
                          child: TextField(
                            controller: _quantityTextController,
                            key: const ValueKey('quantity'),
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                            ),
                            textAlign: TextAlign.center,
                            cursorColor: Colors.green,
                            enabled: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[0-9]')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  _quantityTextController.text = '1';
                                } else {}
                              });
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        quantityControl(
                          fct: () {
                            setState(() {
                              _quantityTextController.text =
                                  (int.parse(_quantityTextController.text) + 1)
                                      .toString();
                            });
                          },
                          icon: CupertinoIcons.plus,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: ProductReviewsSection(
                        productId: getCurrProduct.id,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                      child: Material(
                        elevation: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Total',
                                    color: Colors.red.shade300,
                                    textSize: 20,
                                    isTitle: true,
                                  ),
                                  const SizedBox(height: 5),
                                  FittedBox(
                                    child: Row(
                                      children: [
                                        TextWidget(
                                          text: '${formatPkr(totalPrice)}/',
                                          color: color,
                                          textSize: 20,
                                          isTitle: true,
                                        ),
                                        TextWidget(
                                          text:
                                              '${_quantityTextController.text}Kg',
                                          color: color,
                                          textSize: 16,
                                          isTitle: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Material(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        onTap: _isInCart
                                            ? null
                                            : () async {
                                                final user =
                                                    await AuthGateService
                                                        .requireVerifiedUser(
                                                  context,
                                                  message:
                                                      'Sign in with a verified account to add items to your cart.',
                                                );
                                                if (user == null) return;
                                                if (!context.mounted) return;
                                                await GlobalMethods.addToCart(
                                                    productId:
                                                        getCurrProduct.id,
                                                    quantity: int.parse(
                                                        _quantityTextController
                                                            .text),
                                                    context: context);
                                                await cartProvider.fetchCart();
                                              },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: TextWidget(
                                            text: _isInCart
                                                ? 'In cart'
                                                : 'Add to cart',
                                            color: Colors.white,
                                            textSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Material(
                                      color: Colors.teal.shade700,
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        onTap: () =>
                                            _showSingleProductCheckoutSheet(
                                                context, getCurrProduct.id),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: TextWidget(
                                            text: 'Checkout',
                                            color: Colors.white,
                                            textSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  int? _parsedQuantityOrNull() {
    try {
      final q = int.parse(_quantityTextController.text.trim());
      if (q < 1) return null;
      return q;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showSingleProductCheckoutSheet(
      BuildContext context, String productId) async {
    final q = _parsedQuantityOrNull();
    if (q == null) {
      await GlobalMethods.errorDialog(
        subtitle: 'Enter a valid quantity (1 or more).',
        context: context,
      );
      return;
    }
    final user = await AuthGateService.requireVerifiedUser(
      context,
      message: 'Sign in with a verified account to checkout.',
    );
    if (user == null) {
      return;
    }
    if (!context.mounted) return;

    final productProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final product = productProvider.findProdById(productId);
    final unit = product.isOnSale ? product.salePrice : product.price;
    final lineTotal = unit * q;
    final emailOrId = user.email ?? user.uid;
    final summary =
        'Single item — ${product.title} × $q — ${formatPkr(lineTotal)} — $emailOrId';

    await showManualPaymentCheckoutSheet(
      context,
      summaryLine: summary,
      onPlaceOrder: () => _submitSingleProductCheckout(context, productId, q),
    );
  }

  Future<void> _submitSingleProductCheckout(
      BuildContext context, String productId, int quantity) async {
    final user = await AuthGateService.requireVerifiedUser(
      context,
      message: 'Sign in with a verified account to place orders.',
    );
    if (user == null) return;
    if (!context.mounted) return;

    final productProvider =
        Provider.of<ProductsProvider>(context, listen: false);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ManualCheckoutService.submitPendingManualOrderSingleProduct(
        user: user,
        productProvider: productProvider,
        productId: productId,
        quantity: quantity,
      );
      if (!context.mounted) return;
      await CustomerFlowRefresh.afterSingleProductCheckout(context);
      if (!context.mounted) return;
      Navigator.of(context).pop();

      await Fluttertoast.showToast(
        msg: 'Order placed — pending payment (cart unchanged)',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        await GlobalMethods.errorDialog(
            subtitle: e.toString(), context: context);
      }
    }
  }

  Widget quantityControl(
      {required Function fct, required IconData icon, required Color color}) {
    return Flexible(
      flex: 2,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: color,
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              fct();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            )),
      ),
    );
  }
}
