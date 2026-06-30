## Firebase Configuration Guide

### **Why This Step Matters**
The app uses Firebase for authentication (login/signup). Without proper configuration, the app will crash on startup.

---

## **Option A: Automatic Configuration (Easiest)**

### **1. Install FlutterFire CLI**
```bash
dart pub global activate flutterfire_cli
```

### **2. Run Configuration**
```bash
# From project root (pos_app/)
flutterfire configure
```

### **3. Follow Prompts**
- Select platforms (Android, iOS, Web, etc.)
- Select existing Firebase project or create new
- Auto-generates `lib/firebase_options.dart`

**Done!** File is auto-configured with correct credentials.

---

## **Option B: Manual Configuration**

### **Step 1: Create Firebase Project**

1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Enter project name (e.g., "POS-App")
4. Click "Create project"
5. Wait for initialization (2-3 minutes)

### **Step 2: Enable Authentication**

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Click "Email/Password" provider
4. Toggle to enable
5. Click "Save"

### **Step 3: Get Credentials**

1. Go to **Project Settings** (gear icon)
2. Select your platform (Android/iOS/Web)
3. Copy the following:

**For Android:**
- Go to **Android** section
- Copy: `google-services.json`
- Save to: `android/app/`

**For iOS:**
- Go to **iOS** section
- Copy: `GoogleService-Info.plist`
- Save to: `ios/Runner/`

**For Web:**
- Note the config values (apiKey, projectId, etc.)

### **Step 4: Update firebase_options.dart**

Open `lib/firebase_options.dart` and replace placeholder values:

```dart
// Find these in Firebase Console → Project Settings
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',           // Copy from Firebase Console
  appId: 'YOUR_WEB_APP_ID',             // Copy from Firebase Console
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',          // e.g., 'my-pos-app'
  authDomain: 'YOUR_AUTH_DOMAIN',        // e.g., 'my-pos-app.firebaseapp.com'
  storageBucket: 'YOUR_STORAGE_BUCKET',
);

// Similar for Android, iOS, macOS
```

**Where to find values:**
- **Project ID**: Settings → General tab
- **Web API Key**: Settings → Service Accounts → Web SDK configuration
- **Auth Domain**: Settings → General → Web API configuration
- **Storage Bucket**: Storage section

---

## **Step 5: Verify Configuration**

### **Test Login/Signup:**
```bash
flutter run
```

1. Tap "Sign Up"
2. Enter email: `test@example.com`
3. Enter password: `password123`
4. Click "Sign Up"
5. Should create account and go to home screen

### **Check Firebase Console:**
1. Go to Firebase Console → Authentication
2. Users tab should show your test account

---

## **Common Issues & Solutions**

### ❌ **"Firebase app not initialized"**
- **Cause**: `firebase_options.dart` has placeholder values
- **Fix**: Run `flutterfire configure` or fill credentials manually

### ❌ **"MissingPluginException"**
- **Cause**: Firebase plugin not installed
- **Fix**: Run `flutter pub get`

### ❌ **"Invalid API key"**
- **Cause**: Wrong key copied to `firebase_options.dart`
- **Fix**: Double-check Project Settings credentials

### ❌ **"Email provider is disabled"**
- **Cause**: Email/Password not enabled in Firebase Console
- **Fix**: Go to Authentication → Sign-in method → Enable Email/Password

### ❌ **"App crashes on startup"**
- **Cause**: Firebase credentials invalid or missing
- **Fix**: Verify `firebase_options.dart` has all non-placeholder values

---

## **File Locations for Credentials**

### **Google Services Configuration**

**Android (`android/app/google-services.json`):**
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  ...
}
```

Download from: Firebase Console → Android app setup

**iOS (`ios/Runner/GoogleService-Info.plist`):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist>
  ...
  <key>PROJECT_ID</key>
  <string>your-project-id</string>
  ...
</plist>
```

Download from: Firebase Console → iOS app setup

---

## **Environment-Specific Setup**

### **Development**
```dart
// Use development Firebase project
// Enable Email/Password auth
// Test with test accounts
```

### **Production**
```dart
// Use production Firebase project
// Enable security rules in Firestore (if added)
// Use environment variables for credentials
```

---

## **Security Best Practices**

1. ✅ **Never commit credentials** to GitHub
   - Add `firebase_options.dart` to `.gitignore` if hardcoded

2. ✅ **Use Environment Variables** for production
   ```dart
   // Example (implement based on environment)
   const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
   ```

3. ✅ **Enable Authentication Rules** in Firebase Console
   - Authentication → Rules
   - Default rules allow signup/login

4. ✅ **Limit API Key** in Firebase Console
   - Settings → API keys
   - Restrict to specific services

---

## **Verification Checklist**

- [ ] Firebase project created
- [ ] Authentication enabled (Email/Password)
- [ ] `firebase_options.dart` has real credentials (not placeholders)
- [ ] Android: `google-services.json` in `android/app/`
- [ ] iOS: `GoogleService-Info.plist` in `ios/Runner/`
- [ ] App runs without crashes
- [ ] Can sign up new account
- [ ] Account appears in Firebase Console
- [ ] Can login with that account

---

## **If Using flutterfire configure**

After running `flutterfire configure`:
1. ✅ `firebase_options.dart` is auto-generated
2. ✅ Platform-specific files are added
3. ✅ `pubspec.yaml` is updated with Firebase plugins
4. Just run `flutter pub get` and `flutter run`

---

## **Next: Run the App**

Once Firebase is configured:

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Or specific platform
flutter run -d ios
flutter run -d chrome
```

**See QUICKSTART.md for testing workflow**

---

**Questions?** Check [Firebase Flutter Docs](https://firebase.google.com/docs/flutter/setup)
