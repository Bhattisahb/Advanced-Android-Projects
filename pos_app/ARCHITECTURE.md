## Smart POS & Full Inventory Management App

A production-ready Flutter application built for a university final lab. This app implements an offline-first architecture with SQLite for local storage and Firebase for authentication.

---

## **Project Architecture**

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants, routes, thresholds
│   ├── utils/
│   │   └── validators.dart            # Input validation functions
│   └── services/
│       └── auth_service.dart          # Firebase Authentication service
│
├── data/
│   ├── models/
│   │   ├── product_model.dart         # Product entity with serialization
│   │   └── stock_history_model.dart   # Stock transaction history
│   │
│   ├── local/
│   │   ├── database_helper.dart       # SQLite initialization & schema
│   │   ├── product_dao.dart           # Product CRUD operations
│   │   └── stock_history_dao.dart     # Stock history CRUD operations
│   │
│   ├── remote/
│   │   └── (Firebase integration for future)
│   │
│   └── repositories/
│       ├── product_repository.dart    # Product business logic
│       └── inventory_repository.dart  # Stock management with transactions
│
├── ui/
│   ├── auth/
│   │   ├── login_screen.dart          # Email/password login
│   │   └── signup_screen.dart         # Account creation
│   │
│   ├── products/
│   │   ├── product_list_screen.dart   # Product catalog display
│   │   └── product_form_screen.dart   # Add/Edit product form
│   │
│   ├── inventory/
│   │   └── inventory_screen.dart      # Stock IN/OUT, low stock alerts
│   │
│   └── shared/
│       └── home_screen.dart           # Dashboard & navigation hub
│
├── firebase_options.dart              # Firebase configuration (template)
└── main.dart                          # App entry point with routing
```

---

## **Key Features**

### **1. Authentication (Firebase)**
- Email/password signup and login
- Secure session management
- Automatic logout support
- Stream-based auth state management

### **2. Product Management (SQLite)**
- Add, edit, delete products
- Fields: name, SKU, price, cost, category, stock quantity
- Timestamp tracking (createdAt, updatedAt)
- SKU uniqueness validation

### **3. Inventory Control**
- **Stock IN**: Record received inventory with optional reasons
- **Stock OUT**: Remove stock with validation (prevents negative stock)
- **Low Stock Alerts**: Products below threshold (default: 5 units)
- **Stock History**: Complete audit trail of all transactions

### **4. Data Integrity**
- **Transactional Operations**: Stock updates and history are atomic
- **Offline-First**: All data stored locally, syncs with Firebase later
- **Input Validation**: Comprehensive validators for all fields

---

## **Getting Started**

### **Prerequisites**
- Flutter 3.10+
- Firebase project (for authentication)

### **1. Install Dependencies**
```bash
flutter pub get
```

### **2. Configure Firebase**

#### **Option A: Auto-generate (Recommended)**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This auto-generates `lib/firebase_options.dart` with your credentials.

#### **Option B: Manual Setup**
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Update `lib/firebase_options.dart` with your project credentials:
   - Get values from Firebase Console → Project Settings
   - Replace `YOUR_*` placeholders

### **3. Run the App**
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

---

## **Database Schema**

### **products table**
```sql
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  sku TEXT UNIQUE NOT NULL,
  price REAL NOT NULL,
  cost REAL NOT NULL,
  category TEXT NOT NULL,
  stockQuantity INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  updatedAt TEXT
)
```

### **stock_history table**
```sql
CREATE TABLE stock_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  productId INTEGER NOT NULL,
  changeType TEXT NOT NULL,        -- 'stockIn', 'stockOut', 'adjustment'
  quantity INTEGER NOT NULL,
  reason TEXT,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (productId) REFERENCES products(id)
)
```

**Indexes**: `stock_history(productId)` for fast product lookup

---

## **Core Classes**

### **Product Model**
```dart
Product(
  id, name, sku, price, cost, category, 
  stockQuantity, createdAt, updatedAt
)

// Methods
- toJson()          // Serialize to JSON
- fromJson()        // Deserialize from JSON
- copyWith()        // Create modified copy
- profitMargin      // Calculate margin %
- isLowStock        // Check if below threshold
```

### **StockHistory Model**
```dart
StockHistory(
  id, productId, changeType, quantity, reason, timestamp
)

enum StockChangeType { stockIn, stockOut, adjustment }
```

### **AuthService**
```dart
AuthService
  - login(email, password)
  - signup(email, password)
  - logout()
  - currentUser (getter)
  - authStateChanges (Stream)
```

### **InventoryRepository**
```dart
InventoryRepository
  - addStockIn(productId, quantity, reason)    // Transactional
  - addStockOut(productId, quantity, reason)   // Transactional
  - adjustStock(productId, adjustment, reason) // Transactional
  - getProductHistory(productId)
  - getLowStockProducts(threshold)
```

---

## **Data Flow**

```
UI Screen
  ↓
Repository (business logic)
  ↓
DAO (database operations)
  ↓
SQLite (local storage)
```

**Transactions ensure:**
- If product update fails, history isn't recorded
- If history fails, product stock isn't updated
- Prevents inconsistent state

---

## **Key Constants**

```dart
AppConstants
  - LOW_STOCK_THRESHOLD = 5
  - DATABASE_NAME = 'pos_app.db'
  - DATABASE_VERSION = 1
  - Routes (LOGIN, SIGNUP, HOME, PRODUCTS, INVENTORY)
```

---

## **Validation Rules**

| Field | Rules |
|-------|-------|
| Email | Must be valid email format |
| Password | Minimum 6 characters |
| Product Name | Non-empty, 2+ characters |
| SKU | Non-empty, unique |
| Price | > 0 |
| Cost | ≥ 0 |
| Quantity | Non-negative integer |

---

## **Routing**

| Route | Screen | Purpose |
|-------|--------|---------|
| `/login` | LoginScreen | User login |
| `/signup` | SignupScreen | Account creation |
| `/home` | HomeScreen | Dashboard (default after login) |
| `/products` | ProductListScreen | View all products |
| `/products/form` | ProductFormScreen | Add/edit product |
| `/inventory` | InventoryScreen | Stock management |

**AuthWrapper**: Auto-routes to login if not authenticated

---

## **Testing the App**

### **Sample Workflow**
1. **Sign Up**: Create account with email/password
2. **Add Product**: Click + button, enter product details
3. **Check Dashboard**: View metrics (total products, stock, low stock count)
4. **Stock IN**: Add received inventory
5. **Stock OUT**: Record sales/usage
6. **View History**: See all transactions
7. **Low Stock Alert**: Products below threshold highlighted in orange

### **Manual Testing Tips**
- Try adding duplicate SKU (should fail)
- Try selling more than available stock (should fail)
- Try negative prices (should fail)
- Logout and login to verify data persistence
- Uninstall app without deleting data to test offline-first

---

## **Firebase Setup (Production)**

### **Steps:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project
3. Enable Authentication:
   - Go to Authentication
   - Enable Email/Password provider
4. Copy credentials and update `firebase_options.dart`
5. (Optional) Enable Firestore/Realtime DB for cloud sync

### **Environment-Specific Configuration**
```
firebase_options.dart contains configs for:
- Android
- iOS
- macOS
- Web
```

---

## **Code Quality**

- **Modular Design**: Separation of concerns (UI, Logic, Data)
- **Clean Code**: Readable variable names, comprehensive comments
- **Error Handling**: Try-catch blocks, user-friendly error messages
- **Validation**: All inputs validated before storage
- **Transactions**: ACID-compliant database operations
- **No Unnecessary Animations**: Focus on correctness

---

## **Future Enhancements**

1. **Cloud Sync**: Push SQLite changes to Firebase Firestore
2. **Offline Queue**: Sync pending changes when online
3. **Reports**: Sales, inventory value, profit analysis
4. **Multi-user**: User roles and permissions
5. **Barcode Scanning**: QR/Barcode product lookup
6. **Export**: PDF/CSV reports
7. **Search Optimization**: Full-text search
8. **Images**: Product photos

---

## **Troubleshooting**

### **Firebase Connection Error**
- Check `firebase_options.dart` has correct credentials
- Verify Firebase project is created and Auth enabled
- Run `flutterfire configure` to regenerate

### **SQLite Error**
- Delete app and reinstall (clears database)
- Check file permissions on device
- Ensure `sqflite` dependency is installed

### **Low Stock Alert Not Showing**
- Check threshold in `AppConstants.LOW_STOCK_THRESHOLD` (default: 5)
- Verify product stockQuantity < threshold

### **Transaction Failed**
- Check internet for Firebase operations
- Verify product exists before stock operations
- Ensure sufficient stock for Stock OUT

---

## **Dependencies**

- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **sqflite**: SQLite database
- **provider**: State management
- **intl**: Internationalization (timestamps)

---

## **Lab Submission Checklist**

- ✅ Offline-first architecture (SQLite mandatory)
- ✅ Modular, readable, well-commented code
- ✅ No unnecessary complexity or animations
- ✅ Firebase Authentication (Email/Password)
- ✅ Product CRUD operations
- ✅ Stock IN/OUT with transactions
- ✅ Low stock alerts (threshold: 5)
- ✅ Stock history/audit trail
- ✅ Clean routing and navigation
- ✅ Input validation
- ✅ Error handling

---

**Built with Flutter | Powered by SQLite & Firebase**
