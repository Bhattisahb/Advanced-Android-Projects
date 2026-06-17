import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Human-readable copy for common Firebase Auth / sign-in failures.
abstract final class AuthErrorMessages {
  AuthErrorMessages._();

  static String describe(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Password is too weak. Use a stronger password.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled for this project.';
        default:
          final m = error.message;
          if (m != null && m.isNotEmpty) return m;
          return 'Something went wrong (${error.code}).';
      }
    }
    if (error is FirebaseException) {
      return error.message ?? error.toString();
    }
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }
}
