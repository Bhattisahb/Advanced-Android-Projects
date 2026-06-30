# Google Drive Implementation Checklist

**Goal**: Enable Google Drive backup functionality in your POS app

---

## Phase 1: Pre-Setup (5 minutes)

- [ ] Read [GOOGLE_DRIVE_QUICK_REFERENCE.md](GOOGLE_DRIVE_QUICK_REFERENCE.md)
- [ ] Have a Google account ready
- [ ] Know your app's bundle ID / package name
- [ ] Have project root directory open

---

## Phase 2: Google Cloud Console Setup (15 minutes)

### Create Project
- [ ] Go to [console.cloud.google.com](https://console.cloud.google.com)
- [ ] Create new project
- [ ] Wait for project initialization

### Enable API
- [ ] Go to APIs & Services → Library
- [ ] Search "Google Drive API"
- [ ] Click on it
- [ ] Press "Enable"
- [ ] Wait for enablement confirmation

### Create OAuth Credentials
- [ ] Go to APIs & Services → Credentials
- [ ] Click "Create Credentials" → "OAuth client ID"
- [ ] Configure OAuth consent screen if first time:
  - [ ] User type: "External"
  - [ ] Enter app name (e.g., "Smart POS")
  - [ ] Add support email (your email)
  - [ ] Add developer contact (your email)
  - [ ] In scopes: Select/add `https://www.googleapis.com/auth/drive`
  - [ ] Save and continue
- [ ] Application type: 
  - [ ] Select "Android" OR "iOS" (based on platform)
  - [ ] For Android: Add SHA-1 fingerprint
  - [ ] For iOS: Add Bundle ID
- [ ] Click "Create"
- [ ] **Save your Client ID** (you'll need this)

### Get SHA-1 (Android only)
- [ ] Run: `./gradlew signingReport`
- [ ] Copy SHA-1 from output
- [ ] Add to OAuth credentials in Cloud Console

---

## Phase 3: Platform Configuration (10 minutes)

### Android Setup
- [ ] Open `android/app/build.gradle`
- [ ] Verify `com.google.android.gms:play-services-auth` dependency
- [ ] Open `android/app/src/main/AndroidManifest.xml`
- [ ] Verify internet permissions exist
- [ ] No code changes needed (already configured)

### iOS Setup
- [ ] Open `ios/Runner/Info.plist`
- [ ] Add your Client ID to GIDClientID key:
  ```
  <key>GIDClientID</key>
  <string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
  ```
- [ ] Add CFBundleURLTypes for URL scheme
- [ ] Run `cd ios && pod install`

### Web Setup
- [ ] Update `web/index.html` if needed (usually auto-configured)
- [ ] Verify origin is registered in Google Cloud Console

---

## Phase 4: Verify Dependencies (5 minutes)

- [ ] Open `pubspec.yaml`
- [ ] Verify these are present:
  ```yaml
  google_sign_in: ^6.1.0
  google_sign_in_web: ^0.12.0
  googleapis: ^12.0.0
  ```
- [ ] Run `flutter pub get`
- [ ] Verify no errors

---

## Phase 5: Code Verification (5 minutes)

- [ ] Verify `lib/core/services/google_drive_service.dart` exists
- [ ] Verify imports are correct in `lib/ui/backup/backup_sync_screen.dart`
- [ ] Verify no compilation errors: `flutter analyze`
- [ ] No build errors: `flutter build apk --analyze` or equivalent

---

## Phase 6: Testing (15 minutes)

### Test 1: Sign In
- [ ] Run: `flutter run`
- [ ] Navigate to Backup & Sync tab
- [ ] Tap "Sign In with Google"
- [ ] Complete Google login
- [ ] Verify: Email shown as "Signed in as"
- [ ] Verify: "Sign Out" button visible

### Test 2: Create & Upload Backup
- [ ] Tap "Create Backup" button
- [ ] Wait for "Backup created successfully"
- [ ] In Local Backups, tap backup menu
- [ ] Select "Upload to Google Drive"
- [ ] Wait for "Cloud backup created"
- [ ] Verify: Backup now appears in "Google Drive Backups"

### Test 3: View Backups
- [ ] Scroll to "Google Drive Backups"
- [ ] Verify: List of backups shows
- [ ] Verify: File names visible
- [ ] Verify: Dates and sizes show

### Test 4: Download Backup
- [ ] In "Google Drive Backups", tap backup menu
- [ ] Select "Download & Restore"
- [ ] Wait for completion
- [ ] Scroll to "Local Backups"
- [ ] Verify: New backup with today's date appears

### Test 5: Delete Backup
- [ ] In "Google Drive Backups", tap backup menu
- [ ] Select "Delete"
- [ ] Confirm deletion
- [ ] Verify: Backup removed from list

### Test 6: Multi-Device (Optional)
- [ ] Build and install on another device
- [ ] Sign in with same Google account
- [ ] Navigate to Backup & Sync
- [ ] Verify: See same backups from first device
- [ ] Download a backup
- [ ] Verify: Can access data

### Test 7: Error Handling
- [ ] Sign in, then turn off internet
- [ ] Try uploading → Verify error message
- [ ] Turn internet back on
- [ ] Try uploading again → Verify it works
- [ ] Sign out and try accessing feature → Verify error

---

## Phase 7: Production Checklist (5 minutes)

Before deploying:
- [ ] All tests passed
- [ ] No error messages in logs
- [ ] Tested with real Google account (not test account)
- [ ] Tested backup/restore workflow end-to-end
- [ ] Tested on actual device (not emulator)
- [ ] Version number updated in `pubspec.yaml`
- [ ] Release notes updated

### Final Verification
- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `flutter build apk --release` (or iOS equivalent)
- [ ] Test released app
- [ ] Deploy to app store / users

---

## Phase 8: Post-Deployment (Optional)

- [ ] Monitor user feedback
- [ ] Check Google Cloud Console logs for errors
- [ ] Verify users can sign in
- [ ] Verify users can upload/download
- [ ] Monitor Google API usage

---

## Troubleshooting During Setup

### Sign In Not Working
- [ ] Check Client ID in Google Cloud Console
- [ ] Verify platform credentials match (package name / bundle ID / SHA-1)
- [ ] Ensure OAuth consent screen is configured
- [ ] Try clearing app data and signing in again

### Upload Fails
- [ ] Check internet connection
- [ ] Verify Google Drive API is enabled
- [ ] Check Google Drive has storage space (15 GB free)
- [ ] Verify backup file is not empty

### Can't See Backups
- [ ] Check if signed in (verify email shown)
- [ ] Try pulling down to refresh list
- [ ] Check Google Drive directly for `POS_App_Backups` folder
- [ ] Try signing out and back in

### Download Fails
- [ ] Check internet connection
- [ ] Try with different backup
- [ ] Check app has storage permission
- [ ] Try signing out and back in

---

## Quick Links

- **Setup Guide**: [GOOGLE_DRIVE_SETUP.md](GOOGLE_DRIVE_SETUP.md)
- **Implementation Details**: [GOOGLE_DRIVE_IMPLEMENTATION.md](GOOGLE_DRIVE_IMPLEMENTATION.md)
- **Quick Reference**: [GOOGLE_DRIVE_QUICK_REFERENCE.md](GOOGLE_DRIVE_QUICK_REFERENCE.md)
- **Google Cloud Console**: https://console.cloud.google.com
- **Google Drive API Docs**: https://developers.google.com/drive/api

---

## Estimated Timeline

| Phase | Time | Total |
|-------|------|-------|
| Pre-Setup | 5 min | 5 min |
| Cloud Console | 15 min | 20 min |
| Platform Config | 10 min | 30 min |
| Verify Dependencies | 5 min | 35 min |
| Code Verification | 5 min | 40 min |
| Testing | 15 min | 55 min |
| Production | 5 min | 60 min |
| **TOTAL** | | **~1 hour** |

---

## Success Criteria

✅ You've succeeded when:

1. [ ] Can sign in to Google
2. [ ] Can create local backup
3. [ ] Can upload to Google Drive
4. [ ] Backup appears in Google Drive's `POS_App_Backups` folder
5. [ ] Can view backup in app's "Google Drive Backups" section
6. [ ] Can download backup
7. [ ] Downloaded backup appears in "Local Backups"
8. [ ] Can delete backup from Google Drive
9. [ ] All operations show appropriate success/error messages
10. [ ] App doesn't crash during any operation

---

## Notes

- 📝 Keep your Client ID safe (but it's not a secret)
- 🔐 Your OAuth credentials are platform-specific
- 📱 Test on real device when possible
- 🌐 Network connectivity is required for all cloud operations
- 💾 Local backups work offline; Google Drive requires internet
- 🔄 You can sign in/out multiple times for testing

---

## Support

If you get stuck:

1. **Check documentation**: [GOOGLE_DRIVE_SETUP.md](GOOGLE_DRIVE_SETUP.md)
2. **Review troubleshooting**: Section in setup guide
3. **Check logs**: Look for detailed error messages
4. **Verify credentials**: Double-check Google Cloud Console
5. **Try again**: Clear app cache and restart app

---

**Status**: Ready to follow this checklist  
**Last Updated**: January 2026  
**Time Estimate**: ~1 hour for complete setup and testing

**Let's go!** 🚀
