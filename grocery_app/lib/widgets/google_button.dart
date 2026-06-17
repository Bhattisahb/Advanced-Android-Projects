import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grocery_app/consts/firebase_consts.dart'
    show authInstance, googleServerClientId;
import 'package:grocery_app/services/auth_gate_service.dart';
import 'package:grocery_app/widgets/text_widget.dart';

import '../services/auth_error_messages.dart';
import '../services/global_methods.dart';

class GoogleButton extends StatefulWidget {
  const GoogleButton({super.key});

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton> {
  bool _isLoading = false;

  Future<void> _googleSignIn(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: googleServerClientId,
      );
      // Clear the plugin’s cached account so Android shows the account chooser
      // instead of silently reusing the last Google account for this app.
      await googleSignIn.signOut();
      final googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) return;

      final googleAuth = await googleAccount.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google did not return the required sign-in tokens.',
        );
      }

      final authResult = await authInstance.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        ),
      );

      final user = authResult.user;
      if (user != null) {
        final isNewUser = authResult.additionalUserInfo?.isNewUser == true;
        final profile = isNewUser
            ? <String, dynamic>{
                'id': user.uid,
                'name': user.displayName,
                'email': user.email,
                'shipping-address': '',
                'userWish': [],
                'userCart': [],
                'isAdmin': false,
                'createdAt': Timestamp.now(),
              }
            : <String, dynamic>{
                'id': user.uid,
                'name': user.displayName,
                'email': user.email,
              };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profile, SetOptions(merge: true));
      }

      if (!context.mounted) return;
      await AuthGateService.routeAfterSignIn(context);
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      final message = error.code == 'sign_in_failed'
          ? 'Google sign-in is not configured for this Android app yet. '
              'Use email/password login for now, or add the debug SHA-1/SHA-256 '
              'keys in Firebase and download a fresh google-services.json.'
          : '${error.message ?? error}';
      GlobalMethods.errorDialog(subtitle: message, context: context);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      GlobalMethods.errorDialog(
        subtitle: AuthErrorMessages.describe(error),
        context: context,
      );
    } catch (error) {
      if (!context.mounted) return;
      GlobalMethods.errorDialog(
        subtitle: AuthErrorMessages.describe(error),
        context: context,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue,
      child: InkWell(
        onTap: _isLoading ? null : () => _googleSignIn(context),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
            color: Colors.white,
            child: _isLoading
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Image.asset(
                    'assets/images/google.png',
                    width: 40.0,
                  ),
          ),
          const SizedBox(
            width: 8,
          ),
          TextWidget(
              text: 'Sign in with google', color: Colors.white, textSize: 18)
        ]),
      ),
    );
  }
}
