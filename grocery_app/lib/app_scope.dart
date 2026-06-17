import 'package:flutter/material.dart';

/// Distinguishes customer vs admin Android builds at runtime (wrapped around [MaterialApp]).
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.isCustomerApp,
    required super.child,
  });

  final bool isCustomerApp;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.isCustomerApp != isCustomerApp;
}
