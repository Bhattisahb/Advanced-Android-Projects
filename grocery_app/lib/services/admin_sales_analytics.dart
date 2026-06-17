import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';

/// PKR totals for paid lines grouped by how payment was received (admin-selected).
/// Legacy or missing [paymentReceivedVia] is counted as **bank**.
class PaidReceivedViaTotals {
  const PaidReceivedViaTotals({
    required this.bankPkr,
    required this.jazzcashPkr,
    required this.easypaisaPkr,
  });

  final double bankPkr;
  final double jazzcashPkr;
  final double easypaisaPkr;

  static const PaidReceivedViaTotals zero = PaidReceivedViaTotals(
    bankPkr: 0,
    jazzcashPkr: 0,
    easypaisaPkr: 0,
  );

  double get totalPkr => bankPkr + jazzcashPkr + easypaisaPkr;
}

class _PaidAggMut {
  double bank = 0;
  double jazzcash = 0;
  double easypaisa = 0;

  void add(double amount, String? via) {
    switch (via?.trim()) {
      case PaymentReceivedVia.jazzcash:
        jazzcash += amount;
        break;
      case PaymentReceivedVia.easypaisa:
        easypaisa += amount;
        break;
      case PaymentReceivedVia.bank:
      default:
        // Bank + anything unknown / legacy → bank column
        bank += amount;
        break;
    }
  }

  PaidReceivedViaTotals seal() => PaidReceivedViaTotals(
        bankPkr: bank,
        jazzcashPkr: jazzcash,
        easypaisaPkr: easypaisa,
      );
}

/// Client-side aggregates over a **sample** of `orders` documents (Spark / no backend jobs).
class OrderSampleAnalytics {
  OrderSampleAnalytics({
    required this.unitsByProductId,
    required this.grossRevenuePkr,
    required this.checkoutCount,
    required this.orderLineCount,
    required this.revenueByProductId,
    required this.salesByDay,
    required this.paymentStatusLineCounts,
    required this.fulfillmentStatusLineCounts,
    required this.paidReceivedViaAmountsByDay,
    required this.paidReceivedViaAmountsByWeek,
    required this.paidReceivedViaAmountsByMonth,
    required this.paidReceivedViaAmountsByYear,
  });

  final Map<String, int> unitsByProductId;

  /// Sum of per-line `price` fields (line totals in PKR). Matches cart math.
  final double grossRevenuePkr;

  /// Distinct checkouts: `groupOrderId` when set, else one batch per document.
  final int checkoutCount;

  final int orderLineCount;
  final Map<String, double> revenueByProductId;

  /// Calendar day (UTC midnight) → sum of line totals that day.
  final Map<DateTime, double> salesByDay;

  final Map<String, int> paymentStatusLineCounts;
  final Map<String, int> fulfillmentStatusLineCounts;

  /// Paid lines only: bucket start → PKR by channel ([paidAt], else [orderDate]).
  final Map<DateTime, PaidReceivedViaTotals> paidReceivedViaAmountsByDay;
  final Map<DateTime, PaidReceivedViaTotals> paidReceivedViaAmountsByWeek;
  final Map<DateTime, PaidReceivedViaTotals> paidReceivedViaAmountsByMonth;
  final Map<DateTime, PaidReceivedViaTotals> paidReceivedViaAmountsByYear;

  double get averageCheckoutPkr =>
      checkoutCount > 0 ? grossRevenuePkr / checkoutCount : 0;

  static OrderSampleAnalytics fromOrderDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final units = <String, int>{};
    var gross = 0.0;
    final batchKeys = <String>{};
    final revenueByProduct = <String, double>{};
    final byDay = <DateTime, double>{};
    final pay = <String, int>{};
    final fulfill = <String, int>{};

    final paidDay = <DateTime, _PaidAggMut>{};
    final paidWeek = <DateTime, _PaidAggMut>{};
    final paidMonth = <DateTime, _PaidAggMut>{};
    final paidYear = <DateTime, _PaidAggMut>{};

    for (final doc in docs) {
      final data = doc.data();
      final lineTotal = _parseMoney(data['price']);
      gross += lineTotal;

      final pid = (data['productId'] ?? '').toString().trim();
      if (pid.isNotEmpty) {
        revenueByProduct[pid] = (revenueByProduct[pid] ?? 0) + lineTotal;
        final rawQty = data['quantity'];
        final qty = switch (rawQty) {
          int i => i,
          num n => n.round(),
          String s => int.tryParse(s) ?? 1,
          _ => int.tryParse(rawQty?.toString() ?? '') ?? 1,
        };
        final add = qty < 1 ? 1 : qty;
        units[pid] = (units[pid] ?? 0) + add;
      }

      final gid = data['groupOrderId']?.toString().trim();
      final batchKey =
          (gid != null && gid.isNotEmpty) ? gid : doc.id;
      batchKeys.add(batchKey);

      final ts = data['orderDate'];
      if (ts is Timestamp) {
        final t = ts.toDate();
        final dayKey = DateTime(t.year, t.month, t.day);
        byDay[dayKey] = (byDay[dayKey] ?? 0) + lineTotal;
      }

      final psRaw = data['paymentStatus']?.toString().trim();
      final psNorm = (psRaw == null || psRaw.isEmpty)
          ? OrderPaymentStatuses.pendingPayment
          : psRaw;
      pay[psNorm] = (pay[psNorm] ?? 0) + 1;

      final fsRaw = data['fulfillmentStatus']?.toString().trim();
      final fsNorm = (fsRaw == null || fsRaw.isEmpty)
          ? FulfillmentStatuses.pending
          : fsRaw;
      fulfill[fsNorm] = (fulfill[fsNorm] ?? 0) + 1;

      if (OrderPaymentStatuses.isPaid(psNorm)) {
        final via = data['paymentReceivedVia']?.toString();
        Timestamp? bucketTs = data['paidAt'] is Timestamp
            ? data['paidAt'] as Timestamp
            : null;
        bucketTs ??=
            data['orderDate'] is Timestamp ? data['orderDate'] as Timestamp : null;
        if (bucketTs != null) {
          final dt = bucketTs.toDate();
          final day = DateTime(dt.year, dt.month, dt.day);
          final weekStart = _startOfWeekMonday(day);
          final monthStart = DateTime(dt.year, dt.month, 1);
          final yearStart = DateTime(dt.year, 1, 1);
          paidDay.putIfAbsent(day, _PaidAggMut.new).add(lineTotal, via);
          paidWeek.putIfAbsent(weekStart, _PaidAggMut.new).add(lineTotal, via);
          paidMonth.putIfAbsent(monthStart, _PaidAggMut.new).add(lineTotal, via);
          paidYear.putIfAbsent(yearStart, _PaidAggMut.new).add(lineTotal, via);
        }
      }
    }

    return OrderSampleAnalytics(
      unitsByProductId: units,
      grossRevenuePkr: gross,
      checkoutCount: batchKeys.length,
      orderLineCount: docs.length,
      revenueByProductId: revenueByProduct,
      salesByDay: byDay,
      paymentStatusLineCounts: pay,
      fulfillmentStatusLineCounts: fulfill,
      paidReceivedViaAmountsByDay: _sealPaidMap(paidDay),
      paidReceivedViaAmountsByWeek: _sealPaidMap(paidWeek),
      paidReceivedViaAmountsByMonth: _sealPaidMap(paidMonth),
      paidReceivedViaAmountsByYear: _sealPaidMap(paidYear),
    );
  }

  static Map<DateTime, PaidReceivedViaTotals> _sealPaidMap(
    Map<DateTime, _PaidAggMut> raw,
  ) {
    return raw.map((k, v) => MapEntry(k, v.seal()));
  }

  /// Monday-start week (local calendar), date normalized to midnight.
  static DateTime _startOfWeekMonday(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final fromMonday = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: fromMonday));
  }

  static double _parseMoney(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
