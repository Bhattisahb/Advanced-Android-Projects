import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth authInstance = FirebaseAuth.instance;

/// Web OAuth client ID from Firebase (`google-services.json` → `oauth_client` client_type 3).
/// Pass to [GoogleSignIn.serverClientId] so Android returns an ID token for Firebase Auth.
const String googleServerClientId =
    '139507359300-h119rf5dschbbq6pa8562bt2unja34gq.apps.googleusercontent.com';
