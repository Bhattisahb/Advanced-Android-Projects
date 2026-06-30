/// Backup & Sync Screen
/// Manage local backups
/// Monitor sync status  
/// Manual backup and restore options

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/core/services/backup_service.dart';
import 'package:pos_app/core/services/sync_manager.dart';
import 'package:pos_app/core/services/google_drive_service.dart';
import 'package:pos_app/core/constants/app_constants.dart';

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({Key? key}) : super(key: key);

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  final BackupService _backupService = BackupService();
  final SyncManager _syncManager = SyncManager();
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  bool _isBackingUp = false;
  bool _isSyncing = false;
  String? _statusMessage;
  List<FileSystemEntity> _localBackups = [];
  bool _googleDriveSignedIn = false;

  @override
  void initState() {
    super.initState();
    _loadLocalBackups();
    _checkGoogleDriveSignIn();
  }

  Future<void> _checkGoogleDriveSignIn() async {
    try {
      final isSignedIn = await _googleDriveService.initialize();
      if (mounted) {
        setState(() => _googleDriveSignedIn = isSignedIn);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _googleDriveSignedIn = false);
      }
    }
  }

  Future<void> _loadLocalBackups() async {
    try {
      final backups = await _backupService.listLocalBackups();
      if (mounted) {
        setState(() => _localBackups = backups);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load backups: $e');
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isBackingUp = true;
      _statusMessage = null;
    });

    try {
      await _backupService.createLocalBackup();
      await _loadLocalBackups();

      if (mounted) {
        _showSuccess('Backup created successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Backup failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _triggerSync() async {
    setState(() {
      _isSyncing = true;
      _statusMessage = null;
    });

    try {
      await _syncManager.performSync();
      _showSuccess('Data synced successfully!');
    } catch (e) {
      _showError('Sync failed: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _deleteBackup(String filePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: const Text('This backup will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _backupService.deleteBackup(filePath);
        await _loadLocalBackups();
        _showSuccess('Backup deleted');
      } catch (e) {
        _showError('Delete failed: $e');
      }
    }
  }

  Future<void> _shareBackup(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.example.pos_app/share');
        await platform.invokeMethod<bool>('shareFile', {
          'filePath': filePath,
          'fileName': fileName,
          'mimeType': 'application/json',
        });
      }
    } catch (e) {
      _showError('Share failed: $e');
    }
  }

  Future<void> _restoreBackup(String filePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text('This will replace all current data with the backup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isBackingUp = true);
        final file = File(filePath);
        final content = await file.readAsString();
        await _backupService.restoreFromContent(content);
        _showSuccess('Backup restored successfully!');
      } catch (e) {
        _showError('Restore failed: $e');
      } finally {
        setState(() => _isBackingUp = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Sync'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncStatus(),
            const SizedBox(height: 24),
            _buildBackupControls(),
            const SizedBox(height: 24),
            _buildLocalBackupsList(),
            const SizedBox(height: 24),
            _buildGoogleDriveSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _syncManager.isOnline ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _syncManager.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _syncManager.isOnline ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backup Controls',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isBackingUp ? null : _createBackup,
            icon: _isBackingUp
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.backup),
            label: Text(_isBackingUp ? 'Creating...' : 'Create Backup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSyncing ? null : _triggerSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.cloud_sync),
            label: Text(_isSyncing ? 'Syncing...' : 'Manual Sync'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalBackupsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Local Backups',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _localBackups.isEmpty
            ? const Text('No backups yet. Create one to get started.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localBackups.length,
                itemBuilder: (context, index) {
                  final backup = _localBackups[index];
                  final file = File(backup.path);
                  final fileName = file.path.split('/').last;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(fileName),
                      subtitle: Text(
                        'Size: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Restore'),
                            onTap: () => _restoreBackup(backup.path),
                          ),
                          PopupMenuItem(
                            child: const Text('Share'),
                            onTap: () => _shareBackup(backup.path),
                          ),
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () => _deleteBackup(backup.path),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildGoogleDriveSection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Google Drive Backup (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Local backups are fully functional. Google Drive sync is optional.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
