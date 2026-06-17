import 'package:flutter/material.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';

/// Fulfillment accent for admin chips and badges.
Color adminFulfillmentAccent(String raw) {
  final status = raw.isEmpty ? FulfillmentStatuses.pending : raw;
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
      return Colors.amber.shade900;
  }
}

/// Payment accent for admin chips (manual confirmation flow).
Color adminPaymentAccent(String? paymentStatus) {
  return OrderPaymentStatuses.isPaid(paymentStatus)
      ? Colors.green.shade700
      : Colors.amber.shade900;
}

/// Short calendar hint for order lists (admin).
String adminRelativeOrderHint(DateTime placed) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(placed.year, placed.month, placed.day);
  final diffDays = today.difference(day).inDays;
  if (diffDays == 0) return 'Today';
  if (diffDays == 1) return 'Yesterday';
  if (diffDays > 0 && diffDays < 7) return '$diffDays days ago';
  return '${placed.day}/${placed.month}/${placed.year}';
}
