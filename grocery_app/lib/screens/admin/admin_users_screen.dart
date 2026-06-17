import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/ultimate_admin.dart';
import 'package:grocery_app/screens/admin/admin_manage_access_screen.dart';
import 'package:grocery_app/screens/admin/admin_orders_screen.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/pull_refresh_extras.dart';

/// Lists all customers; search field filters by name, email, or UID.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  static const routeName = '/admin-users';

  static const int _pageSize = 200;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _controller = TextEditingController();
  List<_UserHit> _allUsers = [];
  bool? _adminOk;
  bool _loading = false;
  String? _error;

  List<_UserHit> get _filtered {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return List<_UserHit>.of(_allUsers);
    return _allUsers.where((h) {
      final name =
          (h.data['name'] ?? h.data['displayName'] ?? '').toString().toLowerCase();
      final email = (h.data['email'] ?? '').toString().toLowerCase();
      final id = h.id.toLowerCase();
      return name.contains(q) || email.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    PullRefreshExtras.addListener(_pullFromGlobal);
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    PullRefreshExtras.removeListener(_pullFromGlobal);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pullFromGlobal() async {
    if (_adminOk == true) await _loadAllUsers();
  }

  Future<void> _bootstrap() async {
    final ok = await const AdminService().isCurrentUserAdmin();
    if (!mounted) return;
    setState(() => _adminOk = ok);
    if (ok) await _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final acc = <_UserHit>[];
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('users')
          .orderBy(FieldPath.documentId)
          .limit(AdminUsersScreen._pageSize);

      while (true) {
        final snap = await query.get();
        for (final d in snap.docs) {
          acc.add(_UserHit(id: d.id, data: d.data()));
        }
        if (snap.docs.length < AdminUsersScreen._pageSize) break;
        query = FirebaseFirestore.instance
            .collection('users')
            .orderBy(FieldPath.documentId)
            .startAfterDocument(snap.docs.last)
            .limit(AdminUsersScreen._pageSize);
      }

      acc.sort((a, b) {
        String key(_UserHit h) {
          final email = (h.data['email'] ?? '').toString().toLowerCase();
          final name =
              (h.data['name'] ?? h.data['displayName'] ?? '').toString().toLowerCase();
          if (email.isNotEmpty) return email;
          if (name.isNotEmpty) return name;
          return h.id;
        }

        return key(a).compareTo(key(b));
      });

      if (mounted) setState(() => _allUsers = acc);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        appBar: AppBar(title: const Text('Customers')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final visible = _filtered;
    final filterText = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            tooltip: 'Refresh list',
            onPressed: _loading ? null : _loadAllUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Filter customers',
                        hintText: 'Name, email, or UID',
                        border: const OutlineInputBorder(),
                        suffixIcon: filterText.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loading && _allUsers.isEmpty
                          ? 'Loading customers…'
                          : '${visible.length} shown'
                              '${_allUsers.isNotEmpty ? ' of ${_allUsers.length}' : ''}'
                              '${filterText.isNotEmpty ? ' (filtered)' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading && _allUsers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 56,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.32),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                filterText.isEmpty
                                    ? 'No customers yet'
                                    : 'No matches',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                filterText.isEmpty
                                    ? 'Registered users will appear here.'
                                    : 'Try a different name, email, or UID.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.58),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: visible.length,
                          itemBuilder: (ctx, i) {
                              final h = visible[i];
                              final name =
                                  (h.data['name'] ?? h.data['displayName'] ?? '')
                                      .toString();
                              final email = (h.data['email'] ?? '').toString();
                              return Card(
                                child: ListTile(
                                  title: Text(name.isEmpty ? h.id : name),
                                  subtitle: Text(
                                    email.isEmpty ? 'UID ${h.id}' : email),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            AdminUserDetailScreen(userId: h.id),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHit {
  _UserHit({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
}

class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  String _ship(Map<String, dynamic>? data) {
    if (data == null) return '';
    final v =
        data['shipping-address'] ?? data['shipping_address'] ?? data['address'];
    return v == null ? '' : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snap.data!;
          if (!doc.exists || doc.data() == null) {
            return const Center(child: Text('User not found'));
          }
          final data = doc.data()!;
          final name =
              (data['name'] ?? data['displayName'] ?? '').toString().trim();
          final email = (data['email'] ?? '').toString();
          final ship = _ship(data);
          final admin = data['isAdmin'] == true;
          final ultimate = isUltimateAdminCustomerEmail(email);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('UID: $userId',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Divider(height: 24),
                      _row('Name', name.isEmpty ? '—' : name),
                      _row('Email', email.isEmpty ? '—' : email),
                      _row('Shipping', ship.isEmpty ? '—' : ship),
                      _row('Admin', ultimate
                          ? 'Yes — ultimate (locked in rules)'
                          : (admin ? 'Yes' : 'No')),
                    ],
                  ),
                ),
              ),
              if (!ultimate) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AdminManageAccessScreen(userId: userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Manage access'),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AdminOrdersScreen.routeName,
                    arguments: userId,
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View orders for this customer'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
