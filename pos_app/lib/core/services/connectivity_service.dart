/// Connectivity Service
/// Monitors internet connection status
/// Notifies listeners when connection changes
/// Works with sync system to trigger auto-sync when online

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isOnline = false;
  late StreamSubscription<ConnectivityResult> _subscription;

  ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  /// Get stream of connectivity status changes
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });
  }

  /// Update connection status
  void _updateStatus(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;

    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionStatusController.add(isOnline);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _subscription.cancel();
    await _connectionStatusController.close();
  }
}
