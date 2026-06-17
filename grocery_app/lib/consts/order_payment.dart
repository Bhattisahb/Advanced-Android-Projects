/// Payment lifecycle stored on each `orders` line doc (manual bank/wallet flow).
abstract final class OrderPaymentStatuses {
  OrderPaymentStatuses._();

  static const pendingPayment = 'pending_payment';
  static const paid = 'paid';

  static bool isPaid(String? raw) =>
      raw != null && raw.trim() == paid;

  static String label(String? raw) {
    switch (raw) {
      case pendingPayment:
        return 'Awaiting payment confirmation';
      case paid:
        return 'Payment received';
      case null:
      case '':
        return 'Order placed';
      default:
        final s = raw.trim();
        return s.isEmpty ? 'Order placed' : s;
    }
  }
}

/// Admin-selected channel when marking payment received (stored on each line).
abstract final class PaymentReceivedVia {
  PaymentReceivedVia._();

  static const bank = 'received_via_bank';
  static const jazzcash = 'received_via_jazzcash';
  static const easypaisa = 'received_via_easypaisa';

  static const List<String> all = [bank, jazzcash, easypaisa];

  static String label(String? raw) {
    switch (raw?.trim()) {
      case bank:
        return 'Bank transfer';
      case jazzcash:
        return 'JazzCash';
      case easypaisa:
        return 'EasyPaisa';
      default:
        return 'Not specified';
    }
  }
}
