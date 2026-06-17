# Firestore Local Backup

This folder contains a free local backup script for Cloud Firestore.

## One-Time Setup

1. Install Node.js LTS from https://nodejs.org/.
2. Download your Firebase service account key from Firebase Console:
   - Project settings
   - Service accounts
   - Generate new private key
3. Put the downloaded JSON file in this folder.
4. Double-click `run_backup.bat`.

## Create A Backup

Run this command from this folder:

```powershell
node backup.js
```

On Windows, you can also double-click:

```text
run_backup.bat
```

The backup file will be created in:

```text
backups/
```

Keep copies of the generated backup file somewhere safe, such as Google Drive,
an external drive, or another computer.

## Important

Never commit your Firebase service account JSON file or files inside `backups`
to GitHub. They are ignored by this folder's `.gitignore`.
