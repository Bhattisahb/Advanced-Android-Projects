/// In-memory choice for this app launch.
///
/// Firebase Auth has no user for browse-only guests, so we keep a small local
/// flag to distinguish "no signed-in user because they chose guest" from
/// "no signed-in user, show login".
abstract final class GuestSession {
  GuestSession._();

  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static void enter() {
    _enabled = true;
  }

  static void exit() {
    _enabled = false;
  }
}
