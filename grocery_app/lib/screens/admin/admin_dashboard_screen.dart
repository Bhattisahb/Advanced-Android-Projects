import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/app_scope.dart';
import 'package:grocery_app/providers/admin_orders_provider.dart';
import 'package:grocery_app/route_paths.dart';
import 'package:grocery_app/screens/admin/admin_home_tiles_screen.dart';
import 'package:grocery_app/screens/admin/admin_insights_screen.dart';
import 'package:grocery_app/screens/admin/admin_orders_screen.dart';
import 'package:grocery_app/screens/admin/admin_products_screen.dart';
import 'package:grocery_app/screens/admin/admin_users_screen.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/push_notification_service.dart';
import 'package:provider/provider.dart';

/// Hub for admin tools. Used inside the store app (Profile) and as home in the admin-only APK.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin-dashboard';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAdminPushTopic());
  }

  /// Store-app admins open this screen via Profile; subscribe them to admin broadcasts.
  Future<void> _ensureAdminPushTopic() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final isAdmin = await const AdminService().isCurrentUserAdmin();
    if (!mounted || !isAdmin) return;
    final scope = AppScope.of(context);
    try {
      await PushNotificationService.syncSession(
        user: user,
        isCustomerApp: scope.isCustomerApp,
        subscribeAdminTopic: true,
      );
    } catch (_) {}
  }

  Future<void> _signOut(BuildContext context) async {
    await PushNotificationService.onSignedOut();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    context.read<AdminOrdersProvider>().resetSession();
    Navigator.of(context).pushNamedAndRemoveUntil(
      RoutePaths.login,
      (route) => false,
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: iconBg.withValues(alpha: 0.18),
                child: Icon(icon, color: iconBg, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: scheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final standaloneAdminApp = !AppScope.of(context).isCustomerApp;
    final scheme = Theme.of(context).colorScheme;
    final email = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(standaloneAdminApp ? 'Grocery Admin' : 'Admin'),
        actions: [
          if (standaloneAdminApp)
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (standaloneAdminApp && email != null && email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signed in',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          Text(
            'Operations',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context: context,
            icon: Icons.insights_rounded,
            iconBg: Colors.indigo.shade700,
            title: 'Sales & insights',
            subtitle: 'Sales KPIs, trends, units, and review sentiment',
            onTap: () =>
                Navigator.pushNamed(context, AdminInsightsScreen.routeName),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context: context,
            icon: Icons.receipt_long_rounded,
            iconBg: scheme.primary,
            title: 'Orders',
            subtitle: 'Fulfillment, batches, and customer totals',
            onTap: () =>
                Navigator.pushNamed(context, AdminOrdersScreen.routeName),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context: context,
            icon: Icons.person_search_rounded,
            iconBg: Colors.teal.shade700,
            title: 'Customers',
            subtitle: 'Browse all accounts; filter by name, email, or UID',
            onTap: () =>
                Navigator.pushNamed(context, AdminUsersScreen.routeName),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context: context,
            icon: Icons.dashboard_customize_outlined,
            iconBg: Colors.pink.shade700,
            title: 'Home shortcuts',
            subtitle: 'Shopper home grid — order, titles, links & photos',
            onTap: () =>
                Navigator.pushNamed(context, AdminHomeTilesScreen.routeName),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context: context,
            icon: Icons.inventory_2_rounded,
            iconBg: Colors.deepPurple.shade600,
            title: 'Products',
            subtitle: 'Search catalog, stock hints, hide from storefront',
            onTap: () =>
                Navigator.pushNamed(context, AdminProductsScreen.routeName),
          ),
        ],
      ),
    );
  }
}
