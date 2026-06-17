import 'package:flutter/material.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/screens/orders/customer_order_batch.dart';
import 'package:grocery_app/screens/orders/customer_order_batch_tile.dart';
import 'package:grocery_app/services/auth_gate_service.dart';
import 'package:grocery_app/widgets/back_widget.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:provider/provider.dart';

import '../../services/utils.dart';
import '../../widgets/text_widget.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/OrderScreen';

  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = await AuthGateService.requireVerifiedUser(
      context,
      message: 'Sign in with a verified account to view your orders.',
    );
    if (user == null) {
      if (mounted) setState(() => _bootstrapping = false);
      return;
    }
    if (!mounted) return;
    await context.read<OrdersProvider>().fetchOrders();
    if (mounted) setState(() => _bootstrapping = false);
  }

  String _batchRefLabel(String key) {
    if (key.length <= 10) return key;
    return '…${key.substring(key.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final ordersProvider = context.watch<OrdersProvider>();
    final ordersList = ordersProvider.getOrders;

    if (_bootstrapping && ordersList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackWidget(),
          elevation: 0,
          title: TextWidget(
            text: 'Your orders',
            color: color,
            textSize: 22,
            isTitle: true,
          ),
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (ordersList.isEmpty) {
      return const EmptyScreen(
        title: 'No orders yet',
        subtitle:
            'After checkout, your orders appear here grouped by purchase. Payment is confirmed manually.',
        buttonText: 'Start shopping',
        imagePath: 'assets/images/cart.png',
      );
    }

    final batches = groupOrdersForCustomer(ordersList);

    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        centerTitle: false,
        title: TextWidget(
          text:
              'Your orders (${batches.length} batch${batches.length == 1 ? '' : 'es'})',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 24),
            sliver: SliverList.separated(
              itemCount: batches.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      'Each card is one checkout. Expand to see items and open details.',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  );
                }
                final batch = batches[index - 1];
                return CustomerOrderBatchTile(
                  lines: batch.lines,
                  batchLabel: 'Ref ${_batchRefLabel(batch.batchKey)}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
