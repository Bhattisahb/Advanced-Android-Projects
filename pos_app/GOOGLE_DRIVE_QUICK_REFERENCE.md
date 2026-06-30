# Google Drive Backup - Quick Reference

## 🚀 Quick Start (5 minutes)

### 1. Sign In
- Open app → **Backup & Sync** tab
- Tap **"Sign In with Google"**
- Complete login

### 2. Create & Upload
- Tap **"Create Backup"**
- Wait for completion
- Tap backup → **"Upload to Google Drive"**

### 3. Download Anytime
- Scroll to **"Google Drive Backups"**
- Select backup
- Tap **"Download & Restore"**

---

## 📋 Checklist for Developers

Before deploying, complete:

### Google Cloud Console
- [ ] Create project at console.cloud.google.com
- [ ] Enable Google Drive API
- [ ] Create OAuth 2.0 credentials
- [ ] Get Client ID

### Android Setup
- [ ] Add Client ID to android/build.gradle (if needed)
- [ ] Get SHA-1 fingerprint: `./gradlew signingReport`
- [ ] Add SHA-1 to OAuth credentials in Cloud Console

### iOS Setup
- [ ] Add Client ID to ios/Runner/Info.plist
- [ ] Add Bundle ID to OAuth credentials in Cloud Console
- [ ] Update Podfile if needed

### Flutter Project
- [ ] Run `flutter pub get`
- [ ] No additional configuration needed in Dart code
- [ ] Service is ready to use

---

## 🎮 User Features

| Feature | How to Use |
|---------|-----------|
| **Sign In** | Tap "Sign In with Google" in Backup & Sync |
| **Create Backup** | Tap "Create Backup" button |
| **Upload** | Tap backup menu → "Upload to Google Drive" |
| **View Backups** | Scroll to "Google Drive Backups" section |
| **Download** | Tap backup → "Download & Restore" |
| **Delete** | Tap backup → "Delete" |
| **Sign Out** | Tap "Sign Out" in Google Drive section |

---

## 🔧 Methods Available

```dart
// GoogleDriveService API
googleDriveService.signIn()                    // Login
googleDriveService.signOut()                   // Logout
googleDriveService.initialize()                // Check login state
googleDriveService.uploadBackup({...})         // Upload file
googleDriveService.listBackups()               // Get all backups
googleDriveService.downloadBackup(fileId)      // Download file
googleDriveService.deleteBackup(fileId)        // Delete file
googleDriveService.isSignedIn()                // Check status
googleDriveService.currentUser                 // Get user info
```

---

## 📁 What Gets Backed Up

All tables are included in each backup:
- ✅ Products
- ✅ Stock History
- ✅ Customers
- ✅ Sales
- ✅ Sale Items
- ✅ Ledger Entries

---

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Sign in fails | Check Client ID in Cloud Console matches app |
| Upload fails | Check internet + Google Drive storage space |
| Can't see backups | Check if signed in + wait for list to load |
| Download fails | Try again + check connection |
| "Not signed in" | Tap "Sign In with Google" first |

---

## 📚 Full Documentation

- **Setup Guide**: [GOOGLE_DRIVE_SETUP.md](GOOGLE_DRIVE_SETUP.md)
- **Implementation Details**: [GOOGLE_DRIVE_IMPLEMENTATION.md](GOOGLE_DRIVE_IMPLEMENTATION.md)
- **Main Docs Index**: [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)

---

## 💡 Pro Tips

1. **Regular Backups**: Create backups weekly
2. **Test Restore**: Periodically download and test backups
3. **Multiple Copies**: Keep both local and Google Drive backups
4. **Clean Old Files**: Delete backups older than 3 months
5. **Secure Account**: Use strong password + 2FA on Google account
6. **Monitor Space**: Check Google Drive available space (15 GB free)

---

## 🎯 Success Criteria

✅ Your setup is complete when:
- [ ] You can sign in with Google
- [ ] You can create and upload a backup
- [ ] You can see the backup in Google Drive's `POS_App_Backups` folder
- [ ] You can download and restore the backup
- [ ] Multiple devices can access the same backups

---

## 📞 Need Help?

1. Check [GOOGLE_DRIVE_SETUP.md](GOOGLE_DRIVE_SETUP.md) troubleshooting section
2. Verify Google Cloud Console credentials
3. Ensure OAuth 2.0 credentials match your platform
4. Check app logs for detailed error messages

---

**Last Updated**: January 2026
**Status**: ✅ Complete & Ready to Use
