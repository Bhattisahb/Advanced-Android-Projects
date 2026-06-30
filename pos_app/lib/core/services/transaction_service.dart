/// Transaction Service
/// Notifies listeners when a new transaction (sale) is created
/// Allows home screen to update recent transactions automatically

import 'package:flutter/material.dart';

class TransactionService extends ChangeNotifier {
  DateTime _lastTransactionTime = DateTime.now();

  DateTime get lastTransactionTime => _lastTransactionTime;

  /// Notify that a new transaction has been created
  void notifyNewTransaction() {
    _lastTransactionTime = DateTime.now();
    notifyListeners();
  }

  /// Reset the service
  void reset() {
    _lastTransactionTime = DateTime.now();
    notifyListeners();
  }
}
