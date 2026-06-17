import 'package:firebase_auth/firebase_auth.dart';

/// Basic format check (Firebase still accepts the address; verification proves ownership).
bool looksLikeEmailFormat(String raw) {
  final v = raw.trim();
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
      .hasMatch(v);
}

/// Email/password accounts must confirm they own the inbox ([User.emailVerified]).
/// Google (and similar) providers typically already mark the email verified.
bool emailPasswordAccountNeedsVerification(User user) {
  final hasEmailPassword = user.providerData.any(
    (UserInfo p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
  );
  return hasEmailPassword && !user.emailVerified;
}
