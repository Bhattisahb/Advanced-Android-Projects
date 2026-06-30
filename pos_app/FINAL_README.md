# Smart POS - Offline-First Point of Sale System

A professional-grade Flutter-based Point of Sale (POS) and Inventory Management application designed for retail businesses. Built with offline-first architecture, REST API sync, and comprehensive backup capabilities.

## Features

### 🔐 Authentication & Security
- **Local Authentication**: SQLite-based user authentication (no cloud dependency)
- **Secure Password Storage**: Hashed passwords with SHA-256 encoding
- **Session Management**: Persistent login with logout functionality

### 📦 Inventory Management
- **Product Management**: Full CRUD operations for products
- **Stock Tracking**: Real-time inventory levels with low-stock alerts
- **Stock IN/OUT**: Record inventory movements with reason tracking
- **History Tracking**: Complete stock movement history with timestamps

### 🛒 POS & Billing
- **Shopping Cart**: Add/edit/remove items with quantity control
- **Discounts**: Percentage or fixed amount discounts per item/cart
- **Tax Calculation**: Automatic tax computation on subtotal
- **Multiple Payment Methods**: Support for cash, card, and other payment types
- **Order Totals**: Real-time calculation of subtotal, discounts, taxes, and final total
- **Customer Management**: Walk-in or registered customers with credit tracking

### 👥 Customer Management
- **Customer Profiles**: Create and manage customer accounts
- **Credit Tracking**: Monitor customer credit balance (DEBIT/CREDIT system)
- **Purchase History**: Track all customer transactions
- **Customer Reports**: Analyze customer spending patterns

### 📊 Reporting & Analytics
- **Daily Sales Report**: Sales breakdown by product with total revenue
- **Monthly Report**: Monthly sales trends and metrics
- **Stock Report**: Current inventory levels and low-stock items
- **Customer Report**: Customer spending analysis with credit tracking
- **Ledger Report**: DEBIT/CREDIT transactions for financial tracking

### ☁️ Cloud Sync & Backup
- **Automatic Sync**: Background sync when internet connection is available
- **Conflict Resolution**: Latest `updatedAt` timestamp wins strategy
- **Retry Logic**: 3 automatic retries with 2-second delays
- **REST API Integration**: Generic backend support (configurable BASE_URL)
- **Local Backup**: JSON export of all data to device storage
- **Cloud Backup**: Upload/download backups to cloud storage
- **Backup Management**: List, restore, and delete backups

### 📱 Offline-First Architecture
- **Full Offline Support**: All features work without internet connection
- **SQLite Database**: Local persistence with 6 optimized tables
- **Smart Sync**: Automatic sync on connectivity changes
- **Unsynced Tracking**: Marks records as synced/unsynced for reliable sync

## Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Provider
- **Local Database**: SQLite (sqflite)
- **REST API**: http
- **Storage**: path_provider
- **Connectivity**: connectivity_plus
- **Database Abstraction**: Custom DAO pattern

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # App-wide constants and routes
│   ├── services/
│   │   ├── auth_service.dart          # Authentication logic
│   │   ├── connectivity_service.dart  # Internet monitoring
│   │   ├── api_service.dart           # REST API client
│   │   ├── sync_manager.dart          # Auto-sync orchestration
│   │   └── backup_service.dart        # Local/cloud backup
│   └── utils/
│       └── database.dart               # SQLite initialization
├── data/
│   ├── local/
│   │   └── *_dao.dart                 # Data Access Objects
│   ├── models/
│   │   └── *_model.dart               # Data models
│   ├── remote/
│   └── repositories/
│       ├── product_repository.dart
│       ├── pos_repository.dart
│       └── inventory_repository.dart
├── ui/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── shared/
│   │   └── home_screen.dart
│   ├── products/
│   │   ├── product_list_screen.dart
│   │   └── product_form_screen.dart
│   ├── inventory/
│   │   └── inventory_screen.dart
│   ├── pos/
│   │   └── pos_screen.dart
│   ├── customers/
│   │   └── customer_management_screen.dart
│   ├── reports/
│   │   └── reports_screen.dart
│   └── backup/
│       └── backup_sync_screen.dart
└── main.dart
```

## Database Schema

### Products Table
- `id` (INTEGER PRIMARY KEY)
- `name` (TEXT UNIQUE)
- `sku` (TEXT UNIQUE)
- `price` (INTEGER, in cents)
- `cost` (INTEGER, in cents)
- `stockQuantity` (INTEGER)
- `createdAt` (DATETIME)
- `updatedAt` (DATETIME)

### Stock History Table
- `id` (INTEGER PRIMARY KEY)
- `productId` (INTEGER, FOREIGN KEY)
- `changeType` (TEXT: "IN" or "OUT")
- `quantity` (INTEGER)
- `reason` (TEXT)
- `timestamp` (DATETIME)

### Customers Table
- `id` (INTEGER PRIMARY KEY)
- `name` (TEXT)
- `phone` (TEXT)
- `email` (TEXT)
- `creditBalance` (INTEGER)
- `createdAt` (DATETIME)
- `updatedAt` (DATETIME)

### Sales Table
- `id` (INTEGER PRIMARY KEY)
- `customerId` (INTEGER, FOREIGN KEY)
- `totalAmount` (INTEGER, in cents)
- `discountAmount` (INTEGER, in cents)
- `taxAmount` (INTEGER, in cents)
- `paymentMethod` (TEXT: "CASH", "CARD", "CREDIT")
- `isSynced` (INTEGER, 0=false, 1=true)
- `createdAt` (DATETIME)
- `updatedAt` (DATETIME)

### Sale Items Table
- `id` (INTEGER PRIMARY KEY)
- `saleId` (INTEGER, FOREIGN KEY)
- `productId` (INTEGER, FOREIGN KEY)
- `quantity` (INTEGER)
- `unitPrice` (INTEGER, in cents)
- `discountAmount` (INTEGER, in cents)

### Ledger Entries Table
- `id` (INTEGER PRIMARY KEY)
- `customerId` (INTEGER, FOREIGN KEY)
- `transactionType` (TEXT: "DEBIT", "CREDIT")
- `amount` (INTEGER, in cents)
- `reason` (TEXT)
- `createdAt` (DATETIME)

## API Endpoints

The app communicates with a REST API backend. Configure the `BASE_URL` in `lib/core/services/api_service.dart`:

```dart
static const String BASE_URL = 'https://your-api.com';
```

### Sync Endpoints
- `POST /api/sales` - Sync sales records
- `POST /api/products` - Sync product updates
- `POST /api/customers` - Sync customer records

### Backup Endpoints
- `POST /api/backups` - Upload backup file
- `GET /api/backups` - List available backups
- `GET /api/backups/{id}` - Download backup file

## Backup Format

Backups are JSON files with the following structure:

```json
{
  "version": "1.0",
  "timestamp": "2024-01-15T10:30:00.000Z",
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

## Getting Started

### Prerequisites
- Flutter 3.10 or higher
- Dart 3.0 or higher
- Android Studio or Xcode for platform-specific setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pos_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint**
   Edit `lib/core/services/api_service.dart`:
   ```dart
   static const String BASE_URL = 'https://your-backend-api.com';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Database Initialization

The SQLite database is automatically created on first app launch. No manual setup required.

## Usage

### First Time Setup
1. Launch the app
2. Create an account via Sign Up
3. Log in with your credentials
4. Start adding products from the Products menu

### Daily Operations
1. **Add Products**: Products > Add Product
2. **Manage Inventory**: Inventory Control > Record Stock IN/OUT
3. **Create Sales**: POS/Billing > Add Items > Checkout
4. **View Reports**: Reports > Select report type

### Backup & Sync
1. Navigate to **Backup & Sync**
2. **Create Local Backup**: Click "Create Backup"
3. **Upload to Cloud**: Select backup > "Upload to Cloud"
4. **Manual Sync**: Click "Manual Sync" to sync with server
5. **Restore**: Upload local backup file to restore data

## Sync Strategy

### Auto Sync
- Triggers automatically when device comes online
- Syncs unsynced sales, products, and customers
- Marks records as synced after successful upload
- Retries failed requests up to 3 times

### Conflict Resolution
- **Latest Wins**: If same record exists on server and local, the one with latest `updatedAt` timestamp is kept
- **Prevent Data Loss**: All records are backed up locally

### Retry Logic
- **Attempts**: 3 automatic retries
- **Delay**: 2 seconds between retries
- **Exponential Backoff**: Can be configured in `api_service.dart`

## Currency & Amounts

All monetary amounts in the database are stored as **integers in cents**:
- Display value: `actualValue / 100` (formatted to 2 decimals)
- Database value: `displayValue * 100` (integer)

Example:
- Product price $9.99 → stored as `999`
- Display: `999 / 100 = 9.99`

## Error Handling

The app includes comprehensive error handling:
- **Network Errors**: Shows "Offline" status and queues for later sync
- **Database Errors**: Displays error message with retry option
- **Validation Errors**: Form validation with helpful error messages
- **Sync Errors**: Auto-retry with manual sync option

## Performance Optimizations

1. **Indexed Queries**: Database indexes on frequently queried columns
2. **Lazy Loading**: Reports load data on-demand
3. **Local Caching**: Frequently accessed data cached in memory
4. **Batch Operations**: Sync operations batched for efficiency
5. **Pagination Ready**: Report screens designed for future pagination

## Security Best Practices

- ✅ Passwords hashed with SHA-256
- ✅ No Firebase (no cloud dependency)
- ✅ Local-first data storage
- ✅ HTTPS recommended for API endpoints
- ✅ Validate all user inputs

## Limitations & Future Enhancements

### Current Limitations
- Single user per device
- No user roles/permissions yet
- Basic conflict resolution strategy
- No end-to-end encryption

### Planned Features
- Multi-user support with roles
- Advanced reporting with filtering
- Barcode scanning integration
- Receipt printing
- Customer self-service portal
- Inventory reordering automation

## Troubleshooting

### App Won't Sync
- Check internet connection
- Verify API endpoint is correct
- Check server logs for errors
- Manually trigger sync from Backup & Sync screen

### Data Not Persisting
- Verify SQLite initialization succeeded
- Check app has storage permissions
- Review database logs in debug mode

### High Memory Usage
- Clear old backup files
- Limit report date ranges
- Restart app periodically

## Build & Deploy

### Debug Build
```bash
flutter run
```

### Release Build (Android)
```bash
flutter build apk --release
```

### Release Build (iOS)
```bash
flutter build ios --release
```

## Support & Contributing

For issues, questions, or contributions:
1. Check existing issues first
2. Provide detailed reproduction steps
3. Include error logs and device info
4. Submit pull request with tests

## License

This project is proprietary. All rights reserved.

## Changelog

### Version 1.0.0 (Current)
- ✅ Complete POS and inventory management
- ✅ Offline-first architecture with SQLite
- ✅ REST API sync with conflict resolution
- ✅ Local and cloud backup functionality
- ✅ Comprehensive reporting
- ✅ Customer and ledger management

---

**Built with Flutter & Provider | Offline-First Architecture | Production Ready**
