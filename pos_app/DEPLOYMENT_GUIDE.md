# Smart POS - Deployment Guide

## Pre-Deployment Checklist

### Code Quality
- [ ] `flutter analyze` shows no errors/warnings
- [ ] All imports are correct
- [ ] No hardcoded values in code
- [ ] API endpoint configured properly
- [ ] Database version matches schema

### Testing
- [ ] Sign up and login tested
- [ ] Add product and verify in database
- [ ] Create sale from start to finish
- [ ] Test offline mode (disable wifi)
- [ ] Create backup and verify file
- [ ] Test all navigation routes
- [ ] Test error scenarios (invalid input)

### Configuration
- [ ] API endpoint URL set in `api_service.dart`
- [ ] Tax rate configured (if using)
- [ ] Low stock threshold set (default: 5)
- [ ] App name and version in `pubspec.yaml`
- [ ] Icons and splash screens configured

### Documentation
- [ ] README.md updated with current info
- [ ] QUICKSTART.md has correct setup steps
- [ ] API documentation up-to-date
- [ ] Troubleshooting guide complete

## Building for Android

### Release APK (for distribution)

```bash
# Step 1: Clean previous builds
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

**APK file size**: ~50-60 MB
**Installation time**: ~1-2 minutes on device

### Release AAB (for Google Play Store)

```bash
# Build App Bundle
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

**AAB file size**: ~35-45 MB (smaller than APK)

### Signed Build (for Google Play Store)

1. **Create keystore** (one time):
   ```bash
   keytool -genkey -v -keystore ~/key.jks \
   -keyalg RSA -keysize 2048 -validity 10000 \
   -alias pos_app
   ```

2. **Update gradle properties** in `android/gradle.properties`:
   ```properties
   MYAPP_RELEASE_STORE_FILE=../key.jks
   MYAPP_RELEASE_KEY_ALIAS=pos_app
   MYAPP_RELEASE_STORE_PASSWORD=your_password
   MYAPP_RELEASE_KEY_PASSWORD=your_password
   ```

3. **Build signed APK**:
   ```bash
   flutter build apk --release
   ```

## Building for iOS

### Requirements
- macOS with Xcode installed
- Apple Developer account
- iOS provisioning profiles

### Steps

```bash
# Step 1: Clean build
flutter clean
flutter pub get

# Step 2: Build for iOS
flutter build ios --release

# Step 3: Open Xcode project
open ios/Runner.xcworkspace

# Step 4: In Xcode:
# - Select "Runner" project
# - Select "General" tab
# - Update Version Number and Build Number
# - Select "Signing & Capabilities"
# - Select team
# - Create release build

# Step 5: Archive and upload to App Store Connect
# Product → Archive → Distribute App
```

## Installing APK on Device

### Method 1: Direct Installation
```bash
flutter install
```

### Method 2: USB Transfer
1. Build APK: `flutter build apk --release`
2. Connect device via USB
3. Copy APK to device
4. On device: Open Files → Select APK → Install

### Method 3: Distribute via Email/Link
1. Build APK
2. Host on server or file sharing service
3. Send download link to users
4. Users download and open APK
5. System prompts for installation

## Testing Before Release

### Manual Test Cases

1. **Authentication**
   - [ ] Sign up new account
   - [ ] Login with correct password
   - [ ] Login fails with wrong password
   - [ ] Logout works
   - [ ] Auto-login on app restart

2. **Products**
   - [ ] Add product with all fields
   - [ ] Edit product details
   - [ ] Delete product
   - [ ] View product in inventory
   - [ ] Search products

3. **Inventory**
   - [ ] Stock IN operation
   - [ ] Stock OUT operation
   - [ ] View stock history
   - [ ] Low stock alert appears
   - [ ] Stock quantity updates correctly

4. **Sales**
   - [ ] Add item to cart
   - [ ] Increase/decrease quantity
   - [ ] Remove item from cart
   - [ ] Apply discount
   - [ ] Tax calculates correctly
   - [ ] Checkout completes
   - [ ] Receipt displays totals

5. **Customers**
   - [ ] Add new customer
   - [ ] Select customer in sale
   - [ ] Credit tracking works
   - [ ] Customer history shows sales

6. **Reports**
   - [ ] Daily report shows sales
   - [ ] Monthly report displays data
   - [ ] Stock report lists items
   - [ ] Customer report shows spending
   - [ ] Ledger report shows transactions

7. **Offline**
   - [ ] Disable wifi
   - [ ] All features still work
   - [ ] Create sale offline
   - [ ] Create backup offline
   - [ ] Enable wifi
   - [ ] Auto-sync triggers
   - [ ] Offline sales synced

8. **Backup**
   - [ ] Create local backup
   - [ ] Backup file created on device
   - [ ] File size displays correctly
   - [ ] Restore from backup (if database support exists)

## Performance Optimization

### Database Performance
- Check indexes on frequently queried columns
- Monitor query execution times
- Archive old records if database grows large

### UI Performance
- Profile with DevTools
- Ensure efficient list building
- Limit rebuild frequency with const widgets

### Network Performance
- Monitor sync duration
- Optimize API requests
- Consider pagination for large datasets

## Security Checklist

- [ ] Remove debug prints from production code
- [ ] Validate all user inputs
- [ ] Use HTTPS for API calls
- [ ] Don't log sensitive data (passwords, tokens)
- [ ] Test with invalid/malicious inputs
- [ ] Review Firebase console (if using)

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| APK installation fails | Check Android version (requires 5.0+) |
| Sync not working | Verify API endpoint and internet connection |
| Database errors | Rebuild APK, data will be reset |
| High app size | Remove unused packages, enable minification |
| Slow startup | Profile with DevTools, optimize initialization |

## Monitoring Post-Deployment

### Crash Reporting
```dart
// Add Firebase Crashlytics for production (optional)
// Or implement custom error tracking
try {
  // Your code
} catch (e) {
  // Log to external service
  logErrorToBackend(e);
}
```

### Usage Analytics (Optional)
```dart
// Track user actions
analytics.logEvent(name: 'sale_completed', parameters: {
  'amount': total,
  'items': itemCount,
});
```

### Performance Monitoring
- Monitor sync duration
- Track backup creation time
- Watch for memory leaks
- Check database size growth

## Rollback Plan

If issues occur:

1. **Immediate**: Notify users to stop using old version
2. **Backup**: Users have local backups
3. **Data Recovery**: Cloud backups available
4. **New Version**: Build and release fix
5. **Migration**: Users update app

## Version Management

### Update Version in pubspec.yaml
```yaml
version: 1.0.0+1
```

Format: `major.minor.patch+buildNumber`

Example progression:
- 1.0.0+1 (Initial release)
- 1.0.1+2 (Bug fix)
- 1.1.0+3 (Feature addition)
- 2.0.0+4 (Major overhaul)

## Release Notes Template

```
Version 1.0.0 - Initial Release

Features:
- Complete POS and billing system
- Offline-first with local SQLite
- Automatic cloud sync
- Local and cloud backup
- Comprehensive reporting
- Customer credit tracking

Bug Fixes:
- Initial release

Known Issues:
- None

System Requirements:
- Android 5.0+
- iOS 11.0+
- Internet for sync (optional)
```

## Play Store Submission (Android)

1. Create Google Play Developer account
2. Create new app in Play Console
3. Fill in app details:
   - App name
   - Description
   - Category
   - Content rating
4. Prepare app signing:
   - Generate upload key
   - Sign APK with upload key
5. Upload AAB/APK to Play Store
6. Fill in release notes
7. Submit for review (24-48 hours)

## App Store Submission (iOS)

1. Enroll in Apple Developer Program
2. Create App ID in Certificates, Identifiers & Profiles
3. Create provisioning profile
4. In Xcode:
   - Set Bundle ID
   - Set Team
   - Set Signing Certificate
5. Archive app in Xcode
6. Upload to App Store Connect
7. Fill in app information:
   - Screenshots
   - Description
   - Keywords
   - Support URL
8. Submit for review (1-3 days)

## Update Deployment

For subsequent updates:

1. Update version in `pubspec.yaml`
2. Update CHANGELOG.md with changes
3. Test thoroughly
4. Build release APK/AAB
5. Upload to stores
6. Notify users of update

## Post-Launch Checklist

- [ ] Monitor crash reports
- [ ] Collect user feedback
- [ ] Track performance metrics
- [ ] Plan next features
- [ ] Update documentation
- [ ] Schedule maintenance windows
- [ ] Prepare next release

---

**Ready to deploy!** Follow this guide for safe and successful app release.
