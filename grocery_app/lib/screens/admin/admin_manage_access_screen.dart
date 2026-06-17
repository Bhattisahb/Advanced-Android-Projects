import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/ultimate_admin.dart';
import 'package:grocery_app/services/admin_service.dart';

/// Lets an admin grant or revoke `isAdmin` on a user document (`users/{userId}`).
class AdminManageAccessScreen extends StatefulWidget {
  const AdminManageAccessScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminManageAccessScreen> createState() =>
      _AdminManageAccessScreenState();
}

class _AdminManageAccessScreenState extends State<AdminManageAccessScreen> {
  bool _loadingGate = true;
  bool _allowed = false;
  bool _ultimateLocked = false;
  bool _saving = false;
  bool _isAdmin = false;
  String _displayLabel = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final ok = await const AdminService().isCurrentUserAdmin();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loadingGate = false;
        _allowed = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (!mounted) return;
      if (!doc.exists || doc.data() == null) {
        setState(() {
          _loadingGate = false;
          _allowed = true;
          _error = 'User document not found';
        });
        return;
      }
      final data = doc.data()!;
      final name =
          (data['name'] ?? data['displayName'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      if (isUltimateAdminCustomerEmail(email)) {
        if (!mounted) return;
        final label =
            name.isNotEmpty ? name : (email.isNotEmpty ? email : widget.userId);
        setState(() {
          _loadingGate = false;
          _allowed = true;
          _ultimateLocked = true;
          _displayLabel = label;
        });
        return;
      }
      setState(() {
        _loadingGate = false;
        _allowed = true;
        _isAdmin = data['isAdmin'] == true;
        _displayLabel =
            name.isNotEmpty ? name : (email.isNotEmpty ? email : widget.userId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGate = false;
        _allowed = true;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'isAdmin': _isAdmin});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAdmin ? 'Admin access granted' : 'Admin access removed',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loadingGate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage access')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage access')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    if (_ultimateLocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage access')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              '$_displayLabel is the ultimate admin. '
              'Admin status is locked by Firestore rules and cannot be changed from this app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage access')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _displayLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            'UID: ${widget.userId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Admins can use the admin app, read all orders, and change customer admin status. '
            'Deploy updated Firestore rules if this update is denied.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Admin privileges'),
            subtitle: const Text('Firestore field: isAdmin'),
            value: _isAdmin,
            onChanged: _saving
                ? null
                : (v) => setState(() {
                      _isAdmin = v;
                    }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: scheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
