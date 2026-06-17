import 'package:flutter/material.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';
import 'package:grocery_app/providers/admin_orders_provider.dart';
import 'package:grocery_app/screens/admin/admin_order_detail_screen.dart';
import 'package:grocery_app/screens/admin/admin_ui_helpers.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:provider/provider.dart';

/// Lists grouped orders with optional filter by [filterUserId] (Firestore uid).
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key, this.filterUserId});

  static const routeName = '/admin-orders';

  final String? filterUserId;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String? _statusChip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrdersProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: const AdminService().isCurrentUserAdmin(),
      builder: (context, authSnap) {
        if (!authSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authSnap.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Orders')),
            body: const Center(child: Text('Admin access required')),
          );
        }

        final provider = context.watch<AdminOrdersProvider>();
        final filtered = provider.groupedOrdersFiltered(
          statusFilter: _statusChip,
          userIdFilter: widget.filterUserId,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
                widget.filterUserId != null ? 'Customer orders' : 'All orders'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: provider.loading ? null : () => provider.refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _statusChip == null,
                      onSelected: (_) => setState(() => _statusChip = null),
                    ),
                    ...FulfillmentStatuses.all.map((s) {
                      final accent = adminFulfillmentAccent(s);
                      final sel = _statusChip == s;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(FulfillmentStatuses.label(s)),
                          selected: sel,
                          selectedColor: accent.withValues(alpha: 0.22),
                          checkmarkColor: accent,
                          labelStyle: TextStyle(
                            color: sel ? accent : null,
                            fontWeight: sel ? FontWeight.w600 : null,
                          ),
                          side: BorderSide(
                            color: sel
                                ? accent
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          onSelected: (_) => setState(() => _statusChip = s),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    provider.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              Expanded(
                child: provider.loading && filtered.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              widget.filterUserId != null
                                  ? 'No orders for this customer.'
                                  : 'No orders yet.',
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final g = filtered[i];
                              final total =
                                  double.tryParse(g.totalOrderPrice) ?? 0;
                              final accent =
                                  adminFulfillmentAccent(g.fulfillmentStatus);
                              final payAccent =
                                  adminPaymentAccent(g.paymentStatus);
                              final placed = g.orderDate.toDate();
                              final scheme = Theme.of(context).colorScheme;
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            AdminOrderDetailScreen(group: g),
                                      ),
                                    ).then((_) {
                                      if (context.mounted) {
                                        provider.refresh();
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                g.userName.isEmpty
                                                    ? g.userId
                                                    : g.userName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            Icon(Icons.chevron_right,
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.35)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Chip(
                                              label: Text(
                                                FulfillmentStatuses.label(
                                                    g.fulfillmentStatus),
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              backgroundColor: accent
                                                  .withValues(alpha: 0.14),
                                              side: BorderSide(
                                                color: accent.withValues(
                                                    alpha: 0.45),
                                              ),
                                              labelStyle: TextStyle(
                                                color: accent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                OrderPaymentStatuses.label(
                                                    g.paymentStatus),
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              backgroundColor: payAccent
                                                  .withValues(alpha: 0.14),
                                              side: BorderSide(
                                                color: payAccent.withValues(
                                                    alpha: 0.45),
                                              ),
                                              labelStyle: TextStyle(
                                                color: payAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${adminRelativeOrderHint(placed)} • '
                                          '${formatPkr(total)} • '
                                          '${g.lines.length} line(s)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.65),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
