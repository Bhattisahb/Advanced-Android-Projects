/// Google Drive Service
/// Handles backup and restore operations with Google Drive
/// Uses Google Sign-In for authentication
/// Uploads/downloads JSON backup files

import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveService {
  // Use GoogleSignIn for authentication
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _currentUser;

  /// Initialize the service and check if already signed in
  Future<bool> initialize() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error initializing Google Drive: $e');
      return false;
    }
  }

  /// Sign in to Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Check if user is signed in
  bool isSignedIn() => _currentUser != null;

  /// Get current signed-in user
  GoogleSignInAccount? get currentUser => _currentUser;
}
