import 'package:flutter/material.dart';
import 'package:grocery_app/screens/admin/admin_orders_screen.dart';
import 'package:grocery_app/screens/orders/orders_screen.dart';
import 'package:grocery_app/services/in_app_notifications_hub.dart';

import '../services/utils.dart';
import '../widgets/text_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _accent = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    InAppNotificationsHub.instance.restore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatAgo(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${at.day}/${at.month}/${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Notifications',
          color: color,
          textSize: 18,
          isTitle: true,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accent,
          unselectedLabelColor: color.withValues(alpha: 0.45),
          indicatorColor: _accent,
          tabs: const [
            Tab(text: 'Orders & alerts'),
            Tab(text: 'Promotions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListenableBuilder(
            listenable: InAppNotificationsHub.instance,
            builder: (context, _) {
              final entries = InAppNotificationsHub.instance.entries;
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 72, color: color.withValues(alpha: 0.35)),
                        const SizedBox(height: 16),
                        Text(
                          'No alerts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Order updates and admin notices appear here and '
                          'in your device notification area.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color.withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final n = entries[i];
                  final tap = n.payload[InAppNotificationsHub.payloadTapAction];
                  return _AlertCard(
                    title: n.title,
                    body: n.body,
                    timeAgo: _formatAgo(n.at),
                    tapHint: tap != null && tap.isNotEmpty
                        ? 'Open orders'
                        : null,
                    onOpen: tap != null && tap.isNotEmpty
                        ? () {
                            final nav = Navigator.of(ctx);
                            if (tap ==
                                InAppNotificationsHub.tapActionCustomerOrders) {
                              nav.pushNamed(OrdersScreen.routeName);
                            } else if (tap ==
                                InAppNotificationsHub.tapActionAdminOrders) {
                              nav.pushNamed(AdminOrdersScreen.routeName);
                            }
                          }
                        : null,
                    onDismiss: () =>
                        InAppNotificationsHub.instance.dismiss(n.id),
                  );
                },
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 72, color: color.withValues(alpha: 0.35)),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing here!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down later to refresh promotions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.onDismiss,
    this.onOpen,
    this.tapHint,
  });

  final String title;
  final String body;
  final String timeAgo;
  final VoidCallback onDismiss;
  final VoidCallback? onOpen;
  final String? tapHint;

  static const Color _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _accent.withValues(alpha: 0.15),
            child: const Icon(Icons.notifications_rounded,
                color: _accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(body),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (onOpen != null && tapHint != null)
                      TextButton(
                        onPressed: onOpen,
                        child: Text(tapHint!),
                      ),
                    TextButton(
                      onPressed: onDismiss,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: onOpen != null
          ? InkWell(
              onTap: onOpen,
              child: content,
            )
          : content,
    );
  }
}
