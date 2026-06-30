## Quick Setup Guide - Smart POS v1.0

### **Prerequisites**
- Flutter 3.10+ 
- Dart 3.0+
- Android Studio or Xcode

### **Step 1: Install Dependencies**
```bash
cd pos_app
flutter pub get
```

### **Step 2: Configure API Endpoint (Optional)**

Edit `lib/core/services/api_service.dart`:
```dart
static const String BASE_URL = 'https://your-api-backend.com';
```

If no backend available, app still works offline with local sync.

### **Step 3: Run App**
```bash
# Android device/emulator
flutter run

# iOS simulator/device
flutter run -d ios

# Specific device
flutter run -d emulator-5554
```

The SQLite database is created automatically on first launch.

### **Step 4: Initial Setup (In App)**

1. **Create Account**
   - Tap "Sign Up"
   - Enter email and password (min 6 chars)
   - Account created and auto-login

2. **Add Your First Product**
   - Home → Products → "+"
   - Enter: Name, SKU, Price, Cost
   - Tap Save

3. **Record Stock**
   - Home → Inventory Control
   - Select product → Stock IN → Enter quantity
   - Stock IN/OUT recorded with timestamp

4. **Create First Sale**
   - Home → POS / Billing
   - Add items to cart
   - Adjust quantities
   - Select payment method
   - Tap Checkout

5. **Create Backup**
   - Home → Backup & Sync
   - Tap "Create Backup"
   - Backup saved to device

### **Step 5: Test Core Features**

| Feature | How to Test |
|---------|------------|
| **Offline** | Turn off Wi-Fi/Mobile, app still works |
| **Products** | Add, edit, delete products |
| **Inventory** | Record Stock IN/OUT, check history |
| **Sales** | Create multiple sales with discounts |
| **Reports** | View Daily/Monthly sales report |
| **Customers** | Add customer, create sale for them |
| **Sync** | Turn internet on, tap Manual Sync |
| **Backup** | Create backup, check device storage |

---

## **Project Features Map**

| Module | Location | Status |
|--------|----------|--------|
| **Auth** | `ui/auth/` | ✅ Complete |
| **Products** | `ui/products/` | ✅ Complete |
| **Inventory** | `ui/inventory/` | ✅ Complete |
| **POS/Billing** | `ui/pos/` | ✅ Complete |
| **Customers** | `ui/customers/` | ✅ Complete |
| **Reports** | `ui/reports/` | ✅ Complete |
| **Backup/Sync** | `ui/backup/` | ✅ Complete |
| **API Sync** | `core/services/api_service.dart` | ✅ Complete |


| `lib/ui/` | Screens and widgets |
| `lib/main.dart` | App entry point |

---

## **Key Files**

| File | What It Does |
|------|-------------|
| `auth_service.dart` | Firebase login/signup |
| `product_dao.dart` | SQLite product operations |
| `inventory_repository.dart` | Stock IN/OUT transactions |
| `product_list_screen.dart` | View products |
| `inventory_screen.dart` | Manage stock |
| `home_screen.dart` | Dashboard |

---

## **Common Tasks**

### **Add a Product**
```
Home → Products → + button → Fill form → Add Product
```

### **Record Stock IN**
```
Home → Inventory Control → Low Stock tab → + button
```

### **Record Stock OUT**
```
Home → Inventory Control → Low Stock tab → - button
```

### **View Stock History**
```
Home → Inventory Control → History tab
```

---

## **Database Location**
- **Android**: `/data/data/com.example.pos_app/databases/pos_app.db`
- **iOS**: App Documents folder
- **Web**: IndexedDB

---

## **Firebase Integration**

After `flutterfire configure`:
- ✅ Firebase initialized
- ✅ Authentication ready
- ✅ Credentials in `firebase_options.dart`

To verify:
1. Signup with test account
2. Check Firebase Console → Authentication tab
3. User should appear in list

---

## **Troubleshooting**

**App won't start?**
- Run `flutter clean && flutter pub get`
- Check `firebase_options.dart` has credentials

**Can't add products?**
- Verify database isn't corrupted
- Delete app → `flutter run` (reinit database)

**Stock operations failing?**
- Check product exists
- Verify stock amount is positive
- Check Firebase is initialized

---

## **Next Steps**

After lab submission:
1. Add product images
2. Implement cloud sync (Firestore)
3. Add sales reports
4. Barcode scanning
5. Multi-user roles

---

**Good luck with your lab! 🚀**
