import 'package:flutter/material.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';
import 'package:grocery_app/models/orders_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/screens/orders/order_detail_screen.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

/// Accent chip colors for fulfillment status on shopper orders list.
Color fulfillmentChipColor(BuildContext context, String status) {
  switch (status) {
    case FulfillmentStatuses.delivered:
      return Colors.green.shade700;
    case FulfillmentStatuses.shipped:
      return Colors.blue.shade700;
    case FulfillmentStatuses.preparing:
      return Colors.deepOrange.shade700;
    case FulfillmentStatuses.cancelled:
      return Colors.grey.shade700;
    default:
      return Colors.amber.shade800;
  }
}

/// Accent for payment status chips on shopper order batches.
Color paymentStatusChipColor(String? paymentStatus) {
  return OrderPaymentStatuses.isPaid(paymentStatus)
      ? Colors.green.shade700
      : Colors.amber.shade800;
}

/// Single expandable card: one checkout batch → line items → tap opens line detail.
class CustomerOrderBatchTile extends StatelessWidget {
  const CustomerOrderBatchTile({
    super.key,
    required this.lines,
    required this.batchLabel,
  });

  final List<OrderModel> lines;
  final String batchLabel;

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final products = context.watch<ProductsProvider>();
    final head = lines.first;
    final total = double.tryParse(head.totalOrderPrice) ?? 0;
    final status = head.fulfillmentStatus.isEmpty
        ? FulfillmentStatuses.pending
        : head.fulfillmentStatus;
    final chipFg = fulfillmentChipColor(context, status);
    final paymentRaw = head.paymentStatus;
    final paymentFg = paymentStatusChipColor(paymentRaw);
    final placed = head.orderDate.toDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsetsDirectional.only(start: 14, end: 8, top: 4, bottom: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.receipt_long_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 22,
            ),
          ),
          title: TextWidget(
            text: '${placed.day}/${placed.month}/${placed.year}',
            color: color,
            textSize: 17,
            isTitle: true,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        FulfillmentStatuses.label(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: chipFg,
                        ),
                      ),
                      backgroundColor: chipFg.withValues(alpha: 0.12),
                      side: BorderSide(color: chipFg.withValues(alpha: 0.35)),
                    ),
                    Chip(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        OrderPaymentStatuses.label(paymentRaw),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: paymentFg,
                        ),
                      ),
                      backgroundColor:
                          paymentFg.withValues(alpha: 0.12),
                      side: BorderSide(
                          color: paymentFg.withValues(alpha: 0.35)),
                    ),
                    Text(
                      '${lines.length} item${lines.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextWidget(
                      text: formatPkr(total),
                      color: const Color(0xFFFF6B35),
                      textSize: 17,
                      isTitle: true,
                    ),
                    const Spacer(),
                    Text(
                      batchLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: lines.map((line) {
                  final p = products.findProdByIdOrNull(line.productId);
                  final title = p?.title ?? line.productId;
                  final img = p?.imageUrl ?? line.imageUrl;
                  final lineTotal = double.tryParse(line.price) ?? 0;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkProductImage(
                        imageUrl: img,
                        width: 48,
                        height: 48,
                        boxFit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '×${line.quantity} · ${formatPkr(lineTotal)}',
                      style: TextStyle(color: color.withValues(alpha: 0.65)),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: color.withValues(alpha: 0.4),
                    ),
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => OrderDetailScreen(order: line),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
