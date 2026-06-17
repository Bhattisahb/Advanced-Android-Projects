import 'package:grocery_app/models/orders_model.dart';

/// One customer checkout: shared `groupOrderId` or a single legacy line.
class CustomerOrderBatch {
  CustomerOrderBatch({
    required this.batchKey,
    required this.lines,
  }) : assert(lines.isNotEmpty);

  final String batchKey;
  final List<OrderModel> lines;

  OrderModel get representative => lines.first;

  /// Latest timestamp among lines (usually identical within a batch).
  DateTime get sortDate => lines
      .map((e) => e.orderDate.toDate())
      .reduce((a, b) => a.isAfter(b) ? a : b);
}

/// Groups flat order lines into checkout batches for the shopper orders UI.
List<CustomerOrderBatch> groupOrdersForCustomer(List<OrderModel> orders) {
  final map = <String, List<OrderModel>>{};
  for (final o in orders) {
    final key = (o.groupOrderId != null && o.groupOrderId!.trim().isNotEmpty)
        ? o.groupOrderId!.trim()
        : o.orderId;
    map.putIfAbsent(key, () => []).add(o);
  }
  final batches = map.entries
      .map((e) => CustomerOrderBatch(batchKey: e.key, lines: e.value))
      .toList()
    ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
  return batches;
}
