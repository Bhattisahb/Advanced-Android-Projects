import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/app_scope.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/route_paths.dart';
import 'package:grocery_app/services/auth_error_messages.dart';
import 'package:grocery_app/services/auth_navigation_helpers.dart';
import 'package:grocery_app/services/email_verification.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/services/push_notification_service.dart';

import 'package:grocery_app/widgets/auth_button.dart';
import 'package:grocery_app/widgets/text_widget.dart';

/// Blocks app access until the user opens the Firebase verification link (email/password).
class VerifyEmailScreen extends StatefulWidget {
  static const routeName = '/VerifyEmailScreen';

  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const Duration _resendCooldown = Duration(seconds: 60);

  bool _busy = false;
  DateTime? _lastVerificationSentAt;

  bool get _canResend {
    final lastSent = _lastVerificationSentAt;
    if (lastSent == null) return true;
    return DateTime.now().difference(lastSent) >= _resendCooldown;
  }

  int get _resendSecondsLeft {
    final lastSent = _lastVerificationSentAt;
    if (lastSent == null) return 0;
    final elapsed = DateTime.now().difference(lastSent);
    final remaining = _resendCooldown - elapsed;
    return remaining.inSeconds.clamp(0, _resendCooldown.inSeconds).toInt();
  }

  Future<void> _resend() async {
    final user = authInstance.currentUser;
    if (user == null) return;
    if (!_canResend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait ${_resendSecondsLeft}s before resending.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      setState(() => _lastVerificationSentAt = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      GlobalMethods.errorDialog(
        subtitle: AuthErrorMessages.describe(e),
        context: context,
      );
    } catch (e) {
      if (!mounted) return;
      GlobalMethods.errorDialog(
        subtitle: AuthErrorMessages.describe(e),
        context: context,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkVerifiedAndContinue() async {
    final user = authInstance.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await user.reload();
      final refreshed = authInstance.currentUser;
      if (!mounted) return;
      if (refreshed != null &&
          !emailPasswordAccountNeedsVerification(refreshed)) {
        AuthNavigationHelpers.replaceStackWithPostAuthHome(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not verified yet. Open the link in the email, then try again.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      GlobalMethods.errorDialog(
        subtitle: AuthErrorMessages.describe(e),
        context: context,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      if (AppScope.of(context).isCustomerApp) {
        await AuthNavigationHelpers.signOutCustomer(context);
      } else {
        await PushNotificationService.onSignedOut();
        await authInstance.signOut();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutePaths.login,
          (_) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeEmail() async {
    await PushNotificationService.onSignedOut();
    await authInstance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RoutePaths.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authInstance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextWidget(
                text: 'Confirm your email',
                color: Theme.of(context).colorScheme.onSurface,
                textSize: 26,
                isTitle: true,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to '
                '${email.isEmpty ? 'your address' : email}. '
                'You must open that link before using your account. '
                'If the address is fake or typed wrong, it will never verify.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'After opening the link, return here and tap continue. '
                'You may need to check spam or promotions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              AuthButton(
                fct: _resend,
                buttonText: _canResend
                    ? 'Resend verification email'
                    : 'Resend in ${_resendSecondsLeft}s',
              ),
              const SizedBox(height: 12),
              AuthButton(
                fct: _checkVerifiedAndContinue,
                buttonText: 'I verified — continue',
                primary: Colors.teal.shade700,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _busy ? null : _signOut,
                child: const Text('Sign out'),
              ),
              TextButton(
                onPressed: _busy ? null : _changeEmail,
                child: const Text('Use a different email'),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
