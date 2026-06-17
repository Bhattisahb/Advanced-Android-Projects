import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_app/screens/cart/cart_widget.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/auth_gate_service.dart';
import '../../services/customer_flow_refresh.dart';
import '../../services/global_methods.dart';
import '../../services/manual_checkout_service.dart';
import '../../services/utils.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/manual_payment_sheet.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemsList =
        cartProvider.getCartItems.values.toList().reversed.toList();
    return cartItemsList.isEmpty
        ? const EmptyScreen(
            title: 'Your cart is empty',
            subtitle: 'Add something and make me happy :)',
            buttonText: 'Shop now',
            imagePath: 'assets/images/cart.png',
          )
        : Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: TextWidget(
                  text: 'Cart (${cartItemsList.length})',
                  color: color,
                  isTitle: true,
                  textSize: 22,
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      GlobalMethods.warningDialog(
                          title: 'Empty your cart?',
                          subtitle: 'Are you sure?',
                          fct: () async {
                            await cartProvider.clearOnlineCart();
                            cartProvider.clearLocalCart();
                          },
                          context: context);
                    },
                    icon: Icon(
                      IconlyBroken.delete,
                      color: color,
                    ),
                  ),
                ]),
            body: Column(
              children: [
                _manualPaymentBanner(color),
                _checkout(ctx: context),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItemsList.length,
                    itemBuilder: (ctx, index) {
                      return ChangeNotifierProvider.value(
                          value: cartItemsList[index],
                          child: CartWidget(
                            q: cartItemsList[index].quantity,
                          ));
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _manualPaymentBanner(Color color) {
    return Material(
      color: Colors.teal.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: Colors.teal.shade800, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pay by bank or Easypaisa / JazzCash, then send your payment screenshot on WhatsApp. '
                'Tap Checkout to see account details and place your order.',
                style: TextStyle(
                  color: color.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkout({required BuildContext ctx}) {
    final Color color = Utils(ctx).color;
    Size size = Utils(ctx).getScreenSize;
    final cartProvider = Provider.of<CartProvider>(ctx);
    final productProvider = Provider.of<ProductsProvider>(ctx);
    double total = 0.0;
    cartProvider.getCartItems.forEach((key, value) {
      final getCurrProduct = productProvider.findProdById(value.productId);
      total += (getCurrProduct.isOnSale
              ? getCurrProduct.salePrice
              : getCurrProduct.price) *
          value.quantity;
    });
    return SizedBox(
      width: double.infinity,
      height: size.height * 0.1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Material(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showManualCheckoutSheet(ctx),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    TextWidget(
                      text: 'Checkout',
                      textSize: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          FittedBox(
            child: TextWidget(
              text: 'Total: ${formatPkr(total)}',
              color: color,
              textSize: 18,
              isTitle: true,
            ),
          ),
        ]),
      ),
    );
  }
}

Future<void> _showManualCheckoutSheet(BuildContext context) async {
  final user = await AuthGateService.requireVerifiedUser(
    context,
    message: 'Sign in with a verified account to checkout.',
  );
  if (user == null) {
    return;
  }
  if (!context.mounted) return;

  final cartProvider = Provider.of<CartProvider>(context, listen: false);
  final productProvider =
      Provider.of<ProductsProvider>(context, listen: false);
  double total = 0;
  cartProvider.getCartItems.forEach((key, value) {
    final p = productProvider.findProdById(value.productId);
    total += (p.isOnSale ? p.salePrice : p.price) * value.quantity;
  });
  final emailOrId = user.email ?? user.uid;
  final summary =
      'Cart checkout — ${formatPkr(total)} — lines: ${cartProvider.getCartItems.length} — $emailOrId';

  await showManualPaymentCheckoutSheet(
    context,
    summaryLine: summary,
    onPlaceOrder: () => _submitManualCheckout(context),
  );
}

Future<void> _submitManualCheckout(BuildContext context) async {
  final user = await AuthGateService.requireVerifiedUser(
    context,
    message: 'Sign in with a verified account to place orders.',
  );
  if (user == null) return;
  if (!context.mounted) return;

  final cartProvider = Provider.of<CartProvider>(context, listen: false);
  final productProvider = Provider.of<ProductsProvider>(context, listen: false);

  if (cartProvider.getCartItems.isEmpty) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await ManualCheckoutService.submitPendingManualOrder(
      user: user,
      cartProvider: cartProvider,
      productProvider: productProvider,
    );
    if (!context.mounted) return;
    await CustomerFlowRefresh.afterFullCartCheckout(context);
    if (!context.mounted) return;
    Navigator.of(context).pop();

    await Fluttertoast.showToast(
      msg: 'Order placed — pending payment confirmation',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  } catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      await GlobalMethods.errorDialog(subtitle: e.toString(), context: context);
    }
  }
}
