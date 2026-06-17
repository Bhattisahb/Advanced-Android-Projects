import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/services/admin_sales_analytics.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/pull_refresh_extras.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:provider/provider.dart';

/// Sales aggregates from recent `orders` lines + review sentiment from ratings.
class AdminInsightsScreen extends StatefulWidget {
  const AdminInsightsScreen({super.key});

  static const routeName = '/admin-insights';

  /// Matches admin orders listing cap; subtitle explains sampling.
  static const int ordersSampleLimit = 500;
  static const int reviewsSampleLimit = 500;
  static const int topProducts = 10;
  static const int recentReviewsCap = 12;

  @override
  State<AdminInsightsScreen> createState() => _AdminInsightsScreenState();
}

class _InsightsData {
  _InsightsData({
    required this.orderAnalytics,
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.recentReviews,
    required this.reviewDocCount,
  });

  final OrderSampleAnalytics orderAnalytics;
  final int positive;
  final int neutral;
  final int negative;
  final List<_ReviewLite> recentReviews;
  final int reviewDocCount;
}

class _ReviewLite {
  const _ReviewLite({
    required this.productId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.sortDate,
    required this.sentimentLabel,
  });

  final String productId;
  final String userName;
  final num rating;
  final String comment;
  final DateTime? sortDate;
  final String sentimentLabel;
}

class _AdminInsightsScreenState extends State<AdminInsightsScreen> {
  bool? _adminOk;
  _InsightsData? _data;
  bool _loadingInitial = false;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    PullRefreshExtras.addListener(_pullFromGlobal);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    PullRefreshExtras.removeListener(_pullFromGlobal);
    super.dispose();
  }

  Future<void> _pullFromGlobal() async {
    if (_adminOk == true) await _load(forceServer: true);
  }

  Future<void> _bootstrap() async {
    final ok = await const AdminService().isCurrentUserAdmin();
    if (!mounted) return;
    setState(() => _adminOk = ok);
    if (ok) await _load(forceServer: false);
  }

  Future<void> _load({required bool forceServer}) async {
    if (_data == null) {
      setState(() {
        _loadingInitial = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }
    try {
      final d = await _fetchInsights(forceServer: forceServer);
      if (!mounted) return;
      setState(() {
        _data = d;
        _loadingInitial = false;
        _refreshing = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('AdminInsightsScreen._load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingInitial = false;
        _refreshing = false;
        _error = e.toString();
      });
    }
  }

  Future<_InsightsData> _fetchInsights({required bool forceServer}) async {
    final opts = GetOptions(
      source: forceServer ? Source.server : Source.serverAndCache,
    );

    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .limit(AdminInsightsScreen.ordersSampleLimit)
        .get(opts);

    final reviewsSnap = await FirebaseFirestore.instance
        .collection('product_reviews')
        .limit(AdminInsightsScreen.reviewsSampleLimit)
        .get(opts);

    final units = ordersSnap.docs;
    final orderAnalytics = OrderSampleAnalytics.fromOrderDocs(units);

    var positive = 0;
    var neutral = 0;
    var negative = 0;
    final reviewsList = <_ReviewLite>[];

    for (final doc in reviewsSnap.docs) {
      final data = doc.data();
      final rating = _parseRating(data['rating']);
      if (rating == null) continue;

      if (rating >= 4) {
        positive++;
      } else if (rating <= 2) {
        negative++;
      } else {
        neutral++;
      }

      final ts = data['updatedAt'] ?? data['createdAt'];
      DateTime? sortDate;
      if (ts is Timestamp) sortDate = ts.toDate();

      reviewsList.add(
        _ReviewLite(
          productId: (data['productId'] ?? '').toString(),
          userName: (data['userName'] ?? '').toString(),
          rating: rating,
          comment: (data['comment'] ?? '').toString(),
          sortDate: sortDate,
          sentimentLabel: rating >= 4
              ? 'Positive'
              : rating <= 2
                  ? 'Negative'
                  : 'Neutral',
        ),
      );
    }

    reviewsList.sort((a, b) {
      final da = a.sortDate;
      final db = b.sortDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    final trimmed = reviewsList.length > AdminInsightsScreen.recentReviewsCap
        ? reviewsList.sublist(0, AdminInsightsScreen.recentReviewsCap)
        : reviewsList;

    return _InsightsData(
      orderAnalytics: orderAnalytics,
      positive: positive,
      neutral: neutral,
      negative: negative,
      recentReviews: trimmed,
      reviewDocCount: reviewsSnap.docs.length,
    );
  }

  num? _parseRating(dynamic v) {
    if (v == null) return null;
    final n = switch (v) {
      num x => x,
      String s => num.tryParse(s),
      _ => num.tryParse(v.toString()),
    };
    if (n == null) return null;
    if (n < 1 || n > 5) return null;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    if (_adminOk == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_adminOk == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales & insights')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & insights'),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Refresh from server',
              onPressed:
                  _loadingInitial ? null : () => _load(forceServer: true),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loadingInitial && _data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null && _data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _load(forceServer: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = _data!;
          final products = context.watch<ProductsProvider>();

          final sortedUnits = data.orderAnalytics.unitsByProductId.entries
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final revenueTop = data.orderAnalytics.revenueByProductId.entries
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topRevenue =
              revenueTop.take(AdminInsightsScreen.topProducts).toList();
          final top =
              sortedUnits.take(AdminInsightsScreen.topProducts).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_error != null && _data != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: scheme.errorContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: scheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onErrorContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Based on up to ${AdminInsightsScreen.ordersSampleLimit} '
                    'order lines and ${AdminInsightsScreen.reviewsSampleLimit} '
                    'reviews from Firestore (sample, not full history).\n'
                    'This load: ${data.orderAnalytics.orderLineCount} order line(s), '
                    '${data.reviewDocCount} review document(s).\n'
                    'Gross sales uses each line\'s `price` (PKR). Checkouts group by '
                    '`groupOrderId` when present.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sales overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              _SalesKpiRow(analytics: data.orderAnalytics),
              const SizedBox(height: 16),
              _SalesTrendChart(salesByDay: data.orderAnalytics.salesByDay),
              const SizedBox(height: 16),
              _StatusBreakdownCard(
                title: 'Payment (order lines)',
                counts: data.orderAnalytics.paymentStatusLineCounts,
                labelForKey: OrderPaymentStatuses.label,
              ),
              const SizedBox(height: 12),
              _StatusBreakdownCard(
                title: 'Fulfillment (order lines)',
                counts: data.orderAnalytics.fulfillmentStatusLineCounts,
                labelForKey: FulfillmentStatuses.label,
              ),
              const SizedBox(height: 20),
              Text(
                'Confirmed payments by channel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Paid lines only · PKR per order line · bucket by paid date '
                '(falls back to order date if paid date missing). '
                'Missing channel is shown under Bank.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 8),
              _PaidReceivedViaBreakdown(analytics: data.orderAnalytics),
              const SizedBox(height: 20),
              Text(
                'Top products (revenue)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (topRevenue.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No product revenue in sample.',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              else
                _RevenueProductsChart(
                  entries: topRevenue,
                  resolveTitle: (pid) =>
                      products.findProdByIdOrNull(pid)?.title ?? pid,
                ),
              const SizedBox(height: 24),
              Text(
                'Hot products (units sold)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (top.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No order lines in sample.',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              else
                _HotProductsChart(
                  entries: top,
                  resolveTitle: (pid) =>
                      products.findProdByIdOrNull(pid)?.title ?? pid,
                ),
              const SizedBox(height: 24),
              Text(
                'Review sentiment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Positive ≥4 ★ • Neutral 3 ★ • Negative ≤2 ★',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 12),
              _SentimentChart(
                positive: data.positive,
                neutral: data.neutral,
                negative: data.negative,
              ),
              const SizedBox(height: 24),
              Text(
                'Recent reviews',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (data.recentReviews.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No reviews in sample.',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              else
                ...data.recentReviews.map(
                  (r) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _sentimentColor(r.rating).withValues(alpha: 0.2),
                        child: Icon(
                          Icons.star_rounded,
                          color: _sentimentColor(r.rating),
                        ),
                      ),
                      title: Text(
                        products.findProdByIdOrNull(r.productId)?.title ??
                            r.productId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.userName.isEmpty ? 'User' : r.userName} • '
                            '${r.rating.toString()} ★ • ${r.sentimentLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (r.comment.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                r.comment.trim(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _sentimentColor(num rating) {
    if (rating >= 4) return Colors.green.shade700;
    if (rating <= 2) return Colors.red.shade700;
    return Colors.amber.shade900;
  }
}

class _SalesKpiRow extends StatelessWidget {
  const _SalesKpiRow({required this.analytics});

  final OrderSampleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tile({
      required IconData icon,
      required String headline,
      required String caption,
    }) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: scheme.primary),
              const SizedBox(height: 8),
              Text(
                headline,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: tile(
                icon: Icons.payments_outlined,
                headline: formatPkr(analytics.grossRevenuePkr),
                caption: 'Gross sales · line totals',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: tile(
                icon: Icons.shopping_bag_outlined,
                headline: '${analytics.checkoutCount}',
                caption: 'Checkouts · distinct batch',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: tile(
                icon: Icons.receipt_long_outlined,
                headline: formatPkr(analytics.averageCheckoutPkr),
                caption: 'Avg checkout',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: tile(
                icon: Icons.list_alt_rounded,
                headline: '${analytics.orderLineCount}',
                caption: 'Order lines loaded',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SalesTrendChart extends StatefulWidget {
  const _SalesTrendChart({required this.salesByDay});

  final Map<DateTime, double> salesByDay;

  @override
  State<_SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<_SalesTrendChart> {
  int _granularity = 0;

  static DateTime _weekStartMonday(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final fromMonday = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: fromMonday));
  }

  static DateTime _bucketDay(DateTime dayKey, int gran) {
    switch (gran) {
      case 3:
        return DateTime(dayKey.year, 1, 1);
      case 2:
        return DateTime(dayKey.year, dayKey.month, 1);
      case 1:
        return _weekStartMonday(dayKey);
      default:
        return DateTime(dayKey.year, dayKey.month, dayKey.day);
    }
  }

  Map<DateTime, double> _aggregatedSales() {
    if (_granularity == 0) {
      return Map<DateTime, double>.from(widget.salesByDay);
    }
    final out = <DateTime, double>{};
    for (final e in widget.salesByDay.entries) {
      final normalized = DateTime(e.key.year, e.key.month, e.key.day);
      final b = _bucketDay(normalized, _granularity);
      out[b] = (out[b] ?? 0) + e.value;
    }
    return out;
  }

  String _chartTitle(int gran) {
    switch (gran) {
      case 3:
        return 'Sales by year (PKR)';
      case 2:
        return 'Sales by month (PKR)';
      case 1:
        return 'Sales by week (PKR)';
      default:
        return 'Sales by day (PKR)';
    }
  }

  String _formatBucket(DateTime d, int sortedLen) {
    switch (_granularity) {
      case 3:
        return '${d.year}';
      case 2:
        return '${d.month}/${d.year}';
      case 1:
        return '${d.month}/${d.day}';
      default:
        return '${d.month}/${d.day}${sortedLen > 14 ? '' : '/${d.year % 100}'}';
    }
  }

  int _trimCap(int gran) {
    switch (gran) {
      case 3:
        return 12;
      case 2:
        return 24;
      case 1:
        return 26;
      default:
        return 28;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.salesByDay.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No dated order lines in this sample (needs `orderDate`).',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
          ),
        ),
      );
    }

    final aggregated = _aggregatedSales();
    var sorted = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final cap = _trimCap(_granularity);
    if (sorted.length > cap) {
      sorted = sorted.sublist(sorted.length - cap);
    }

    final vals = sorted.map((e) => e.value).toList();
    final maxY = vals.reduce(max) * 1.12;
    final capY = maxY > 0 ? maxY : 1.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chartTitle(_granularity),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Daily')),
                      ButtonSegment(value: 1, label: Text('Weekly')),
                      ButtonSegment(value: 2, label: Text('Monthly')),
                      ButtonSegment(value: 3, label: Text('Yearly')),
                    ],
                    selected: {_granularity},
                    onSelectionChanged: (s) {
                      setState(() => _granularity = s.first);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (sorted.length - 1).toDouble(),
                  minY: 0,
                  maxY: capY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: capY > 5 ? capY / 4 : null,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: sorted.length <= 16,
                        reservedSize: 28,
                        interval:
                            max(1, (sorted.length / 7).ceil().toDouble()),
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if (i < 0 || i >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              _formatBucket(sorted[i].key, sorted.length),
                              style: TextStyle(
                                fontSize: 9,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.58),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          if (value > capY) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            space: 0,
                            child: Text(
                              value.round().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          scheme.inverseSurface.withValues(alpha: 0.92),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots
                            .map((s) {
                              final i = s.x.round();
                              if (i < 0 || i >= sorted.length) return null;
                              final e = sorted[i];
                              return LineTooltipItem(
                                '${_formatBucket(e.key, sorted.length)}\n',
                                TextStyle(
                                  color: scheme.onInverseSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                                children: [
                                  TextSpan(
                                    text: formatPkr(e.value),
                                    style: TextStyle(
                                      color: scheme.onInverseSurface
                                          .withValues(alpha: 0.92),
                                    ),
                                  ),
                                ],
                              );
                            })
                            .whereType<LineTooltipItem>()
                            .toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < sorted.length; i++)
                          FlSpot(i.toDouble(), sorted[i].value),
                      ],
                      isCurved: true,
                      color: scheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: sorted.length <= 16,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: scheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidReceivedViaBreakdown extends StatefulWidget {
  const _PaidReceivedViaBreakdown({required this.analytics});

  final OrderSampleAnalytics analytics;

  @override
  State<_PaidReceivedViaBreakdown> createState() =>
      _PaidReceivedViaBreakdownState();
}

class _PaidReceivedViaBreakdownState extends State<_PaidReceivedViaBreakdown> {
  int _granularity = 0;

  Map<DateTime, PaidReceivedViaTotals> get _map {
    switch (_granularity) {
      case 1:
        return widget.analytics.paidReceivedViaAmountsByWeek;
      case 2:
        return widget.analytics.paidReceivedViaAmountsByMonth;
      case 3:
        return widget.analytics.paidReceivedViaAmountsByYear;
      default:
        return widget.analytics.paidReceivedViaAmountsByDay;
    }
  }

  static PaidReceivedViaTotals _sumMap(
    Map<DateTime, PaidReceivedViaTotals> m,
  ) {
    var b = 0.0;
    var j = 0.0;
    var e = 0.0;
    for (final v in m.values) {
      b += v.bankPkr;
      j += v.jazzcashPkr;
      e += v.easypaisaPkr;
    }
    return PaidReceivedViaTotals(
      bankPkr: b,
      jazzcashPkr: j,
      easypaisaPkr: e,
    );
  }

  String _periodLabel(DateTime key) {
    switch (_granularity) {
      case 3:
        return '${key.year}';
      case 2:
        return '${key.month}/${key.year}';
      case 1:
        return 'Week of ${key.day}/${key.month}/${key.year}';
      default:
        return '${key.day}/${key.month}/${key.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = _map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final totals = _sumMap(_map);
    const cap = 36;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Daily')),
                ButtonSegment(value: 1, label: Text('Weekly')),
                ButtonSegment(value: 2, label: Text('Monthly')),
                ButtonSegment(value: 3, label: Text('Yearly')),
              ],
              selected: {_granularity},
              onSelectionChanged: (s) {
                setState(() => _granularity = s.first);
              },
            ),
            const SizedBox(height: 6),
            Text(
              'JC = JazzCash · EP = EasyPaisa',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                'No paid lines with a date in this sample.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              )
            else ...[
              _paidChannelHeaderRow(context),
              const Divider(height: 20),
              for (final e in entries.take(cap))
                _paidChannelDataRow(context, _periodLabel(e.key), e.value),
              if (entries.length > cap)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Showing newest $cap of ${entries.length} periods.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ),
              const Divider(height: 24),
              Text(
                'Totals (sample)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              _paidChannelDataRow(
                context,
                'All buckets',
                totals,
                emphasize: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paidChannelHeaderRow(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        );
    return Row(
      children: [
        Expanded(flex: 2, child: Text('Period', style: style)),
        Expanded(
          child: Text(
            'Bank',
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          child: Text(
            'JC',
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          child: Text(
            'EP',
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _paidChannelDataRow(
    BuildContext context,
    String period,
    PaidReceivedViaTotals t, {
    bool emphasize = false,
  }) {
    final baseStyle = emphasize
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodySmall;

    Widget cell(double amount) => Expanded(
          child: Text(
            formatPkr(amount),
            textAlign: TextAlign.right,
            style: baseStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              period,
              style: baseStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          cell(t.bankPkr),
          cell(t.jazzcashPkr),
          cell(t.easypaisaPkr),
        ],
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  const _StatusBreakdownCard({
    required this.title,
    required this.counts,
    this.labelForKey,
  });

  final String title;
  final Map<String, int> counts;
  final String Function(String key)? labelForKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            if (total == 0)
              Text(
                'No data.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              )
            else
              ...entries.map((e) {
                final frac = e.value / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              labelForKey?.call(e.key) ?? e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${e.value} (${(frac * 100).round()}%)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 7,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Wide enough per bar column for 2-line labels; scrolls horizontally on phones.
double _scrollableBarChartWidth(BuildContext context, int barCount) {
  const leftAxisReserve = 46.0;
  const minSlot = 88.0;
  final needed = leftAxisReserve + barCount * minSlot;
  final viewport = MediaQuery.sizeOf(context).width - 40;
  return max(needed, viewport);
}

Widget _productBarBottomTitle({
  required ColorScheme scheme,
  required String title,
  required TitleMeta meta,
}) {
  return SideTitleWidget(
    meta: meta,
    space: 4,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          height: 1.2,
          color: scheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    ),
  );
}

class _RevenueProductsChart extends StatelessWidget {
  const _RevenueProductsChart({
    required this.entries,
    required this.resolveTitle,
  });

  final List<MapEntry<String, double>> entries;
  final String Function(String productId) resolveTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = entries.map((e) => e.value).reduce(max);
    final titles = entries.map((e) => resolveTitle(e.key)).toList();
    final barColor = Colors.teal.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _scrollableBarChartWidth(context, titles.length),
            height: 312,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        scheme.inverseSurface.withValues(alpha: 0.92),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final name = titles[group.x.toInt()];
                      return BarTooltipItem(
                        '$name\n',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: formatPkr(rod.toY),
                            style: TextStyle(
                              color: scheme.onInverseSurface
                                  .withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= titles.length) {
                          return const SizedBox.shrink();
                        }
                        return _productBarBottomTitle(
                          scheme: scheme,
                          title: titles[i],
                          meta: meta,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 0,
                          child: Text(
                            value.round().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(
                  entries.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value,
                        color: barColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HotProductsChart extends StatelessWidget {
  const _HotProductsChart({
    required this.entries,
    required this.resolveTitle,
  });

  final List<MapEntry<String, int>> entries;
  final String Function(String productId) resolveTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final titles = entries.map((e) => resolveTitle(e.key)).toList();
    final barColor = scheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _scrollableBarChartWidth(context, titles.length),
            height: 312,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        scheme.inverseSurface.withValues(alpha: 0.92),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final name = titles[group.x.toInt()];
                      return BarTooltipItem(
                        '$name\n',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} units sold',
                            style: TextStyle(
                              color: scheme.onInverseSurface
                                  .withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= titles.length) {
                          return const SizedBox.shrink();
                        }
                        return _productBarBottomTitle(
                          scheme: scheme,
                          title: titles[i],
                          meta: meta,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 0,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(
                  entries.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value.toDouble(),
                        color: barColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SentimentChart extends StatelessWidget {
  const _SentimentChart({
    required this.positive,
    required this.neutral,
    required this.negative,
  });

  final int positive;
  final int neutral;
  final int negative;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = positive + neutral + negative;

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No rated reviews in sample.',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      );
    }

    final posColor = Colors.green.shade600;
    final neuColor = Colors.amber.shade800;
    final negColor = Colors.red.shade600;

    Widget legend(String label, int count, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('$label ($count)'),
        ],
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                legend('Positive', positive, posColor),
                legend('Neutral', neutral, neuColor),
                legend('Negative', negative, negColor),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  sections: [
                    if (positive > 0)
                      PieChartSectionData(
                        color: posColor,
                        value: positive.toDouble(),
                        radius: 52,
                        title: '${((positive / total) * 100).round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    if (neutral > 0)
                      PieChartSectionData(
                        color: neuColor,
                        value: neutral.toDouble(),
                        radius: 52,
                        title: '${((neutral / total) * 100).round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    if (negative > 0)
                      PieChartSectionData(
                        color: negColor,
                        value: negative.toDouble(),
                        radius: 52,
                        title: '${((negative / total) * 100).round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
