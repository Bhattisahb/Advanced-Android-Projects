/// Optional hooks for routes that keep local Firestore/state outside shared providers.
///
/// Screens register in [initState] and unregister in [dispose].
class PullRefreshExtras {
  PullRefreshExtras._();

  static final List<Future<void> Function()> _listeners = [];

  static void addListener(Future<void> Function() listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void removeListener(Future<void> Function() listener) {
    _listeners.remove(listener);
  }

  static Future<void> runRegistered() async {
    final copy = List<Future<void> Function()>.from(_listeners);
    await Future.wait(copy.map((fn) async {
      try {
        await fn();
      } catch (_) {}
    }));
  }
}
