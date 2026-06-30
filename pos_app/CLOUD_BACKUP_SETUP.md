# Cloud Backup Setup Guide

## Overview
The POS app supports uploading backups to a cloud backend server. By default, the cloud upload is disabled because the API backend is not configured.

## Current Status
- ✅ **Local Backups**: Fully functional - backups are created and stored on the device
- ✅ **Google Drive**: Optional backup to Google Drive (requires OAuth setup)
- ⏳ **Cloud Backups**: Requires backend API configuration

## Configuring Cloud Backup

### Option 1: Set Up Your Own Backend Server

To enable cloud backups, you need to:

1. **Create a Backend API Server** with the following endpoints:

#### 1.1 Backup Upload Endpoint
```
POST /api/backups
Content-Type: application/json

Request Body:
{
  "fileName": "pos_backup_1234567890.json",
  "content": "{...backup JSON...}",
  "timestamp": "2024-01-05T10:30:00.000Z"
}

Response (Success):
{
  "id": "backup_id_or_filename",
  "message": "Backup uploaded successfully"
}
```

#### 1.2 Backup Download Endpoint
```
GET /api/backups/{backupId}

Response:
{
  "fileName": "pos_backup_1234567890.json",
  "content": "{...backup JSON...}",
  "timestamp": "2024-01-05T10:30:00.000Z"
}
```

#### 1.3 Backup List Endpoint
```
GET /api/backups

Response:
{
  "backups": [
    {
      "id": "backup_id_1",
      "fileName": "pos_backup_1.json",
      "timestamp": "2024-01-05T10:30:00.000Z",
      "size": 1024
    }
  ]
}
```

### Option 2: Configure the API Service

1. **Open** `lib/core/services/api_service.dart`

2. **Update the BASE_URL:**
```dart
static const String BASE_URL = 'https://your-api-server.com';
```

3. **Adjust endpoints if needed:**
```dart
static const String BACKUPS_ENDPOINT = '/api/backups';
```

### Option 3: Use a Third-Party Backend Service

You can use services like:
- Firebase Cloud Storage (configure via separate service)
- AWS S3 (requires custom implementation)
- Custom REST API on any server
- Mobile Backend as a Service (MBaaS) like Supabase, Appwrite, etc.

## Testing Cloud Backups

1. **Navigate** to the Backup & Sync screen
2. **Create a Local Backup** - This will always work offline
3. **Click Upload to Cloud** on any backup file
4. **Check the logs** for status:
   - ✅ Success: "Cloud backup created"
   - ❌ Error: Shows the API error message

## Error Handling

The app provides clear error messages:

- **"Cloud API not configured..."** - BASE_URL not set or still set to example.com
- **"Failed to upload backup: 401..."** - Authentication issue
- **"Failed to upload backup: 404..."** - Endpoint not found
- **"Failed to upload backup: 500..."** - Server error

## Implementation Notes

### Backup JSON Format
```json
{
  "version": "1.0",
  "timestamp": "2024-01-05T10:30:00.000Z",
  "tables": {
    "products": [...],
    "stock_history": [...],
    "customers": [...],
    "sales": [...]
  }
}
```

### API Service Configuration

**File:** `lib/core/services/api_service.dart`

Key constants to configure:
```dart
static const String BASE_URL = 'YOUR_API_URL'; // Required
static const String BACKUPS_ENDPOINT = '/api/backups'; // Adjust if needed
static const int RETRY_COUNT = 3; // Automatic retries
static const Duration RETRY_DELAY = Duration(seconds: 2);
```

## Security Considerations

1. **Use HTTPS** - Always use encrypted connections
2. **Authentication** - Implement API key or OAuth 2.0
3. **Data Validation** - Validate backup content on the server
4. **Encryption** - Consider encrypting backups in transit and at rest
5. **Storage** - Implement proper access controls on the server

## Troubleshooting

### "Cloud API not configured"
- Check that BASE_URL is set to your actual server
- Ensure it doesn't contain "example.com"

### Upload hangs or times out
- Check network connectivity
- Verify your server is running and accessible
- Check the RETRY_COUNT and RETRY_DELAY settings
- Look for firewall/network issues

### 401 Unauthorized errors
- Implement authentication in your API service
- Add API key headers or OAuth tokens

### File size issues
- Some servers have upload size limits
- Configure your server to accept the backup size

## Disabling Cloud Backup

If you don't need cloud backups, the app still works perfectly with:
- ✅ Local backups (always available)
- ✅ Google Drive backups (optional)

Local backups provide full offline functionality and device storage.

## Next Steps

1. Set up your backend API following the endpoint specifications above
2. Update BASE_URL in ApiService
3. Test the upload functionality
4. Monitor logs for any issues

For more information, see [ARCHITECTURE.md](ARCHITECTURE.md) for the complete system design.
