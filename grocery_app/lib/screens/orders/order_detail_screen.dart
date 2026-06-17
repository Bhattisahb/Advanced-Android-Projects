import 'package:flutter/material.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';
import 'package:grocery_app/models/orders_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../../services/utils.dart';
import '../../widgets/back_widget.dart';

/// Details for one Firestore `orders` line (one product line per doc).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  static const Color _accent = Color(0xFFFF6B35);

  String _fmtDate() {
    final d = order.orderDate.toDate();
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String? _fmtPaidAt() {
    final p = order.paidAt;
    if (p == null) return null;
    final d = p.toDate();
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _paymentMethodLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw == 'demo_university_project') return 'Demo (university project)';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final productProvider = Provider.of<ProductsProvider>(context);
    final product = productProvider.findProdByIdOrNull(order.productId);
    final title = product?.title ?? 'Product (${order.productId})';
    final lineTotal = double.tryParse(order.price) ?? 0.0;
    final orderTotal = double.tryParse(order.totalOrderPrice) ?? lineTotal;

    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Order details',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0.5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Order reference',
                    color: color,
                    textSize: 14,
                    isTitle: true,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    order.groupOrderId ?? order.orderId,
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                  if (order.groupOrderId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Line id: ${order.orderId}',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  _row(context, 'Placed on', _fmtDate()),
                  _row(context, 'Customer',
                      order.userName.isEmpty ? '—' : order.userName),
                  _row(
                    context,
                    'Payment status',
                    OrderPaymentStatuses.label(order.paymentStatus),
                  ),
                  _row(
                    context,
                    'Payment method',
                    _paymentMethodLabel(order.paymentMethod),
                  ),
                  if (_fmtPaidAt() != null)
                    _row(context, 'Paid at', _fmtPaidAt()!),
                  if (OrderPaymentStatuses.isPaid(order.paymentStatus))
                    _row(
                      context,
                      'Paid via',
                      PaymentReceivedVia.label(order.paymentReceivedVia),
                    ),
                  _row(
                    context,
                    'Fulfillment',
                    FulfillmentStatuses.label(order.fulfillmentStatus),
                  ),
                  if (order.shippingAddress.trim().isNotEmpty)
                    _row(context, 'Ship to', order.shippingAddress.trim()),
                  if (order.adminNotes.trim().isNotEmpty)
                    _row(context, 'Store note', order.adminNotes.trim()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextWidget(
            text: 'Item in this order',
            color: color,
            textSize: 18,
            isTitle: true,
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0.5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkProductImage(
                      imageUrl: order.imageUrl,
                      width: 88,
                      height: 88,
                      boxFit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: title,
                          color: color,
                          textSize: 17,
                          isTitle: true,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quantity: ${order.quantity}',
                          style:
                              TextStyle(color: color.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Line total: ${formatPkr(lineTotal)}',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: 'Order total',
                  color: color,
                  textSize: 18,
                  isTitle: true,
                ),
                TextWidget(
                  text: formatPkr(orderTotal),
                  color: _accent,
                  textSize: 20,
                  isTitle: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'If your checkout had multiple items, each appears as a separate row on the orders list; '
            'they share the same order reference above.',
            style: TextStyle(
              color: color.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final color = Utils(context).color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.55),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
