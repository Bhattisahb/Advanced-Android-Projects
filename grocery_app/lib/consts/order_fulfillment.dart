/// Fulfillment lifecycle stored on each `orders` line doc (same value across a batch).
abstract final class FulfillmentStatuses {
  FulfillmentStatuses._();

  static const pending = 'pending';
  static const preparing = 'preparing';
  static const shipped = 'shipped';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static const List<String> all = [
    pending,
    preparing,
    shipped,
    delivered,
    cancelled,
  ];

  static String label(String raw) {
    switch (raw) {
      case pending:
        return 'Pending';
      case preparing:
        return 'Preparing';
      case shipped:
        return 'Shipped';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return raw.isEmpty ? 'Pending' : raw;
    }
  }
}
