import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';
import 'package:grocery_app/consts/order_payment.dart';
import 'package:grocery_app/models/orders_model.dart';
import 'package:grocery_app/providers/admin_orders_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/screens/admin/admin_ui_helpers.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:provider/provider.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.group});

  static const routeName = '/admin-order-detail';

  final AdminGroupedOrder group;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late String _status;
  late TextEditingController _notesController;
  late String _paymentReceivedViaChoice;
  bool _saving = false;
  bool _markingPayment = false;

  @override
  void initState() {
    super.initState();
    _status = widget.group.fulfillmentStatus;
    if (!FulfillmentStatuses.all.contains(_status)) {
      _status = FulfillmentStatuses.pending;
    }
    _notesController =
        TextEditingController(text: widget.group.lines.first.adminNotes);
    final existing =
        widget.group.lines.first.paymentReceivedVia?.trim();
    _paymentReceivedViaChoice =
        existing != null && PaymentReceivedVia.all.contains(existing)
            ? existing
            : PaymentReceivedVia.bank;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AdminOrdersProvider>().updateGroupFulfillment(
            groupKey: widget.group.groupKey,
            fulfillmentStatus: _status,
            adminNotes: _notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fulfillment updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markPaymentReceived() async {
    setState(() => _markingPayment = true);
    try {
      await context.read<AdminOrdersProvider>().markGroupPaymentReceived(
            groupKey: widget.group.groupKey,
            paymentReceivedVia: _paymentReceivedViaChoice,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment marked as received')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _markingPayment = false);
    }
  }

  String? _fmtPaidAt(Timestamp? p) {
    if (p == null) return null;
    final d = p.toDate();
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>();
    final g = widget.group;
    final addr = g.lines.first.shippingAddress.trim();
    final paymentAccent = adminPaymentAccent(g.paymentStatus);

    return FutureBuilder<bool>(
      future: const AdminService().isCurrentUserAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Orders')),
            body: const Center(child: Text('Admin access required')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Order detail')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        'Batch: ${g.groupKey}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('Customer: ${g.userName}'),
                      Text('User ID: ${g.userId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      if (addr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Ship to: $addr'),
                      ],
                      const Divider(height: 24),
                      Text(
                        'Cart total: ${formatPkr(double.tryParse(g.totalOrderPrice) ?? 0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(
                              OrderPaymentStatuses.label(g.paymentStatus),
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor:
                                paymentAccent.withValues(alpha: 0.14),
                            side: BorderSide(
                              color: paymentAccent.withValues(alpha: 0.45),
                            ),
                            labelStyle: TextStyle(
                              color: paymentAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (g.paymentReceived)
                            Icon(
                              Icons.check_circle,
                              color: paymentAccent,
                              size: 22,
                            ),
                        ],
                      ),
                      if (_fmtPaidAt(g.lines.first.paidAt) != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Confirmed at: ${_fmtPaidAt(g.lines.first.paidAt)!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (g.paymentReceived) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Received via: '
                          '${PaymentReceivedVia.label(g.paymentReceivedVia)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                      if (!g.paymentReceived) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Payment received via',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PaymentReceivedVia.all.map((id) {
                            final sel = _paymentReceivedViaChoice == id;
                            final scheme = Theme.of(context).colorScheme;
                            return FilterChip(
                              label: Text(PaymentReceivedVia.label(id)),
                              selected: sel,
                              onSelected: (_saving || _markingPayment)
                                  ? null
                                  : (_) => setState(
                                        () => _paymentReceivedViaChoice = id,
                                      ),
                              selectedColor:
                                  scheme.primaryContainer.withValues(alpha: 0.65),
                              checkmarkColor: scheme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: (_saving || _markingPayment)
                              ? null
                              : _markPaymentReceived,
                          icon: _markingPayment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.payments_outlined),
                          label: Text(
                            _markingPayment
                                ? 'Updating…'
                                : 'Mark payment received',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fulfillment status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FulfillmentStatuses.all.map((s) {
                  final sel = _status == s;
                  final accent = adminFulfillmentAccent(s);
                  final scheme = Theme.of(context).colorScheme;
                  return FilterChip(
                    label: Text(FulfillmentStatuses.label(s)),
                    selected: sel,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _status = s),
                    selectedColor: accent.withValues(alpha: 0.22),
                    checkmarkColor: accent,
                    labelStyle: TextStyle(
                      color: sel ? accent : scheme.onSurface,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: sel ? accent : scheme.outlineVariant,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Admin notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                enabled: !_saving,
              ),
              const SizedBox(height: 24),
              Text('Items (${g.lines.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...g.lines.map((line) => _LineTile(line: line, products: products)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save status'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.products});

  final OrderModel line;
  final ProductsProvider products;

  @override
  Widget build(BuildContext context) {
    final p = products.findProdByIdOrNull(line.productId);
    final title = p?.title ?? line.productId;
    final img = p?.imageUrl ?? line.imageUrl;
    final lineTotal = double.tryParse(line.price) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: NetworkProductImage(
            imageUrl: img,
            width: 56,
            height: 56,
            boxFit: BoxFit.cover,
          ),
        ),
        title: Text('$title × ${line.quantity}'),
        subtitle: Text(formatPkr(lineTotal)),
      ),
    );
  }
}
