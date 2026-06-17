import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/screens/auth/login.dart';
import 'package:grocery_app/screens/auth/verify_email_screen.dart';
import 'package:grocery_app/services/auth_navigation_helpers.dart';
import 'package:grocery_app/services/email_verification.dart';

enum AuthGateStatus {
  guest,
  needsEmailVerification,
  verified,
}

class AuthGateResult {
  const AuthGateResult({
    required this.status,
    this.user,
  });

  final AuthGateStatus status;
  final User? user;

  bool get canUsePrivateData =>
      status == AuthGateStatus.verified && user != null;
}

/// One place for auth/session decisions used by login, splash gates, and
/// protected customer actions.
abstract final class AuthGateService {
  AuthGateService._();

  static Future<AuthGateResult> resolve({bool reload = true}) async {
    final current = authInstance.currentUser;
    if (current == null) {
      return const AuthGateResult(status: AuthGateStatus.guest);
    }

    if (reload) {
      try {
        await current.reload();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-disabled' || e.code == 'user-not-found') {
          await authInstance.signOut();
          return const AuthGateResult(status: AuthGateStatus.guest);
        }
        rethrow;
      }
    }

    final refreshed = authInstance.currentUser;
    if (refreshed == null) {
      return const AuthGateResult(status: AuthGateStatus.guest);
    }

    if (emailPasswordAccountNeedsVerification(refreshed)) {
      return AuthGateResult(
        status: AuthGateStatus.needsEmailVerification,
        user: refreshed,
      );
    }

    return AuthGateResult(status: AuthGateStatus.verified, user: refreshed);
  }

  static Future<void> routeAfterSignIn(BuildContext context) async {
    final result = await resolve();
    if (!context.mounted) return;

    switch (result.status) {
      case AuthGateStatus.guest:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      case AuthGateStatus.needsEmailVerification:
        openVerifyEmail(context);
      case AuthGateStatus.verified:
        AuthNavigationHelpers.replaceStackWithPostAuthHome(context);
    }
  }

  static void openVerifyEmail(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const VerifyEmailScreen()),
      (_) => false,
    );
  }

  static Future<User?> requireVerifiedUser(
    BuildContext context, {
    String message = 'Please sign in with a verified account to continue.',
  }) async {
    final result = await resolve();
    if (!context.mounted) return null;

    switch (result.status) {
      case AuthGateStatus.verified:
        return result.user;
      case AuthGateStatus.needsEmailVerification:
        final open = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Verify your email'),
            content: const Text(
              'Open the verification link sent to your email before using '
              'cart, wishlist, checkout, orders, reviews, or profile data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Verify now'),
              ),
            ],
          ),
        );
        if (open == true && context.mounted) {
          openVerifyEmail(context);
        }
        return null;
      case AuthGateStatus.guest:
        final open = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Sign in required'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sign in'),
              ),
            ],
          ),
        );
        if (open == true && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          );
        }
        return null;
    }
  }
}
