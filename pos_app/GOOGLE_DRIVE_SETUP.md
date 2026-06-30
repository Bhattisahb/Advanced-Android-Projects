# Google Drive Backup Setup Guide

## Overview
The POS App now includes **Google Drive backup** functionality, allowing you to securely backup your business data to Google Drive and restore it anytime.

---

## Features

✅ **Automatic Backup Organization**
- All backups stored in a `POS_App_Backups` folder in Google Drive
- Organized and easy to manage

✅ **One-Click Upload**
- Upload any local backup to Google Drive with a single tap
- Backup progress indicator

✅ **Secure Download & Restore**
- Download backups from Google Drive
- Automatically validates backup integrity
- Saves to local storage for easy access

✅ **Backup Management**
- View all Google Drive backups with creation date and file size
- Delete old or unwanted backups
- Automatic sorting (newest first)

✅ **Multiple Backup Options**
- Upload to Google Drive (recommended)
- Upload to generic REST API cloud (if configured)
- Keep local backups on device

---

## Setup Instructions

### Step 1: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project:
   - Click "Select a Project" → "New Project"
   - Enter project name (e.g., "POS App Backups")
   - Click "Create"
3. Enable Google Drive API:
   - Go to "APIs & Services" → "Library"
   - Search for "Google Drive API"
   - Click on it and press "Enable"
4. Create OAuth 2.0 Credentials:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - If prompted, configure the OAuth consent screen:
     - User type: External
     - Enter app name, support email, developer contact
     - Scopes: Select `https://www.googleapis.com/auth/drive`
     - Save and continue
   - Application type: Android / iOS (select as needed)
   - For Android: Add SHA-1 fingerprint from your keystore
   - For iOS: Add Bundle ID
   - Click "Create"
5. Download the configuration:
   - Note the Client ID (for web)
   - Note the OAuth credentials

### Step 2: Configure Android (if building for Android)

1. Update `android/app/build.gradle`:
   ```gradle
   dependencies {
       // ... other dependencies
       implementation 'com.google.android.gms:play-services-auth:20.5.0'
   }
   ```

2. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

3. (Optional) Add SHA-1 fingerprint to Google Cloud Console:
   ```bash
   ./gradlew signingReport
   ```
   Copy the SHA-1 from the output and add it to your OAuth 2.0 Android credentials.

### Step 3: Configure iOS (if building for iOS)

1. Update `ios/Podfile`:
   ```ruby
   # Uncomment if needed for Google Sign-In
   target 'Runner' do
     # ... existing pods
   end
   ```

2. Update `ios/Runner/Info.plist`:
   ```xml
   <key>GIDClientID</key>
   <string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

### Step 4: Update Dependencies

Run:
```bash
flutter pub get
```

This installs:
- `google_sign_in` - Authentication with Google
- `googleapis` - Google Drive API client
- `google_sign_in_web` - Web support (if building for web)

---

## Using Google Drive Backup

### Sign In

1. Open the app and navigate to **Backup & Sync**
2. Scroll to **Google Drive Backup** section
3. Tap **"Sign In with Google"**
4. Complete the Google login flow
5. Grant permissions for Google Drive access

### Create & Upload Backup

1. Tap **"Create Backup"** to create a local backup
2. In **Local Backups** section, tap the backup file
3. Select **"Upload to Google Drive"** from the menu
4. Wait for upload to complete
5. Success message confirms upload

### View Google Drive Backups

Once signed in, scroll down to **"Google Drive Backups"** section:
- Shows all backups with creation date and file size
- Newest backups appear first
- Tap the menu (⋮) for options

### Download & Restore

1. In **"Google Drive Backups"**, tap the backup menu (⋮)
2. Select **"Download & Restore"**
3. Backup is validated and saved to local storage
4. Success message confirms download
5. Backup now appears in **"Local Backups"**

### Delete Backup

1. Tap the backup menu (⋮)
2. Select **"Delete"**
3. Confirm deletion
4. Backup is removed from Google Drive

### Sign Out

1. In **Google Drive Backup** section
2. Tap **"Sign Out"**
3. You'll need to sign in again to upload/download

---

## Backup File Format

Backups are stored as JSON files with this structure:

```json
{
  "version": "1.0",
  "timestamp": "2024-01-15T10:30:00Z",
  "tables": {
    "products": [...],
    "stock_history": [...],
    "customers": [...],
    "sales": [...],
    "sale_items": [...],
    "ledger_entries": [...]
  }
}
```

---

## Troubleshooting

### "Sign In Failed"
- Check Google Cloud Console credentials are correct
- Verify OAuth consent screen is configured
- Ensure Client ID matches your app configuration
- Try clearing app cache and signing in again

### "Upload Failed"
- Check internet connection
- Verify Google Drive API is enabled in Google Cloud Console
- Ensure you have storage space in Google Drive
- Check that backup file is not corrupted

### "Cannot Find Backups in Google Drive"
- Backups are in a folder named `POS_App_Backups`
- This folder is created automatically on first upload
- If not visible, check if it was created in a different location

### "Downloaded Backup Won't Restore"
- Ensure you have internet connection
- Check that backup file size > 0 bytes
- Verify app has permission to access local storage
- Try deleting and re-downloading the backup

### Permissions Issues
- For Android: Grant storage and internet permissions in app settings
- For iOS: Allow access when prompted
- For Web: Cookies must be enabled

---

## Security & Privacy

✅ **Your Data is Safe**
- Backups stored in your Google Drive account
- Only you can access them (controlled by Google Drive permissions)
- App requests only Google Drive scope (no other permissions)
- Backup files are JSON format (human-readable)

✅ **Google Account Security**
- Uses official Google Sign-In SDK
- No passwords stored locally
- Session expires after inactivity
- Sign out when not in use

---

## Best Practices

1. **Regular Backups**
   - Create backups weekly or after major operations
   - More frequent during high-activity periods

2. **Multiple Copies**
   - Keep both local and Google Drive backups
   - Don't delete all backups at once

3. **Test Restoration**
   - Periodically download and test backups
   - Ensure restoration process works when needed

4. **Monitor Storage**
   - Check Google Drive storage space
   - Archive old backups if needed

5. **Account Security**
   - Use a strong Google account password
   - Enable two-factor authentication on Google account
   - Sign out from shared devices

---

## Advanced: Manual Google Drive Access

If the app can't access your backups, you can:

1. Sign in to [Google Drive](https://drive.google.com)
2. Find the `POS_App_Backups` folder
3. Download backup JSON files manually
4. Store safely for manual restoration

---

## FAQ

**Q: Can I access backups from multiple devices?**
A: Yes! Sign in with the same Google account on any device and access all backups.

**Q: What if I lose my Google account access?**
A: Keep local backups on your device as a secondary copy.

**Q: How much data can I backup?**
A: Limited by Google Drive storage (typically 15 GB free).

**Q: Can I backup automatically?**
A: Currently manual. Automatic backup can be added in future updates.

**Q: Is my data encrypted?**
A: Data is encrypted in transit to Google Drive. Backups at rest use Google Drive's encryption.

**Q: Can I share backups with other users?**
A: You can share via Google Drive, but each device needs the app to restore.

---

## Support

For issues:
1. Check this guide first
2. Review the Troubleshooting section
3. Check app logs for error messages
4. Contact support with error details

---

## Next Steps

- ✅ Set up Google Cloud Console
- ✅ Configure your platform (Android/iOS)
- ✅ Install app and test Google Drive backup
- ✅ Create your first backup
- ✅ Test restore process

Happy backing up! 🚀
