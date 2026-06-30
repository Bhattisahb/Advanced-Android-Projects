## Testing & Validation Guide

Complete guide to test all features of the Smart POS app.

---

## **Pre-Testing Checklist**

- [ ] Firebase configured (`firebase_options.dart` updated)
- [ ] `flutter pub get` completed
- [ ] App runs without errors
- [ ] SQLite database initialized

---

## **1. Authentication Testing**

### **Test: Sign Up**

**Steps:**
1. Launch app (should show LoginScreen)
2. Tap "Sign Up"
3. Enter:
   - Email: `test@example.com`
   - Password: `password123`
   - Confirm: `password123`
4. Tap "Sign Up"

**Expected:**
- ✅ Account created
- ✅ Auto-login to HomeScreen
- ✅ User appears in Firebase Console → Authentication

**Test Edge Cases:**
```
Scenario: Invalid email
Input: test@
Expected: Show error "Please enter a valid email address"

Scenario: Weak password
Input: pass
Expected: Show error "Password must be at least 6 characters"

Scenario: Passwords don't match
Input: password123 vs password456
Expected: Show error "Passwords do not match"

Scenario: Email already exists
Input: test@example.com (same as before)
Expected: Show error "Email is already registered"
```

### **Test: Login**

**Steps:**
1. From HomeScreen, tap menu → Logout
2. On LoginScreen, enter:
   - Email: `test@example.com`
   - Password: `password123`
3. Tap "Login"

**Expected:**
- ✅ Successful login
- ✅ Navigate to HomeScreen
- ✅ Dashboard loads with metrics

**Test Edge Cases:**
```
Scenario: Wrong password
Input: test@example.com / wrongpass
Expected: Error "Wrong password provided"

Scenario: Non-existent account
Input: nonexistent@example.com
Expected: Error "No user found with this email"
```

---

## **2. Product Management Testing**

### **Test: Add Product**

**Steps:**
1. From HomeScreen, tap "Products"
2. Tap + button (FAB)
3. Fill form:
   - Name: `USB Cable`
   - SKU: `USB-001`
   - Selling Price: `9.99`
   - Cost: `4.50`
   - Category: `Electronics`
   - Stock: `50`
4. Tap "Add Product"

**Expected:**
- ✅ Success message shown
- ✅ Product appears in list
- ✅ Stored in SQLite database

**Test Edge Cases:**
```
Scenario: Empty name
Expected: Error "Product name is required"

Scenario: Duplicate SKU
Input: SKU = USB-001 (same as above)
Expected: Error "A product with this SKU already exists"

Scenario: Invalid price
Input: Price = 0 or -5
Expected: Error "Price must be greater than 0"

Scenario: Invalid cost
Input: Cost = -5
Expected: Error "Cost cannot be negative"

Scenario: Missing fields
Expected: Validation errors on empty required fields
```

### **Test: View Products**

**Steps:**
1. On ProductListScreen, view list
2. Product should show:
   - Name, SKU, stock quantity
   - Price and cost
   - "Low Stock" badge if stock < 5

**Expected:**
- ✅ All products displayed correctly
- ✅ Low stock badge shows in orange for stock < 5

### **Test: Edit Product**

**Steps:**
1. On ProductListScreen, tap product
2. Modify a field (e.g., Price: 11.99)
3. Tap "Update Product"

**Expected:**
- ✅ Success message
- ✅ Product list shows updated values
- ✅ Database updated

### **Test: Delete Product**

**Steps:**
1. On ProductListScreen, long-press a product
2. Tap "Delete"
3. Confirm in dialog

**Expected:**
- ✅ Success message
- ✅ Product removed from list
- ✅ Can't find it when searching

### **Test: Search Products**

**Steps:**
1. On ProductListScreen, type in search
2. Search: `USB`
3. Results should filter in real-time

**Expected:**
- ✅ Shows only matching products
- ✅ Case-insensitive (USB, usb, Usb all work)
- ✅ Searches name and SKU

---

## **3. Stock Management Testing**

### **Test: Stock IN**

**Steps:**
1. Go to HomeScreen → Inventory Control
2. Click "Low Stock" tab (or wait for item with stock < 5)
3. For any product, tap + button (Stock IN)
4. Enter:
   - Quantity: `20`
   - Reason: `Purchase order PO-001`
5. Tap "Confirm"

**Expected:**
- ✅ Stock updated: old stock + 20
- ✅ "Stock updated successfully" message
- ✅ Record appears in History tab
- ✅ Database shows transaction

**Test Edge Cases:**
```
Scenario: Zero quantity
Input: Quantity = 0
Expected: Error "Please enter a valid quantity"

Scenario: Negative quantity
Input: Quantity = -5
Expected: Error "Please enter a valid quantity"

Scenario: Large number
Input: Quantity = 999
Expected: ✅ Stock updated to 999+
```

### **Test: Stock OUT**

**Steps:**
1. Go to Inventory Control → Low Stock tab
2. Pick a product with stock > 5
3. Tap - button (Stock OUT)
4. Enter:
   - Quantity: `5`
   - Reason: `Sale`
5. Tap "Confirm"

**Expected:**
- ✅ Stock decreased by 5
- ✅ Record in History tab
- ✅ Prevents negative stock

**Test Edge Cases:**
```
Scenario: Sell more than available
Product stock: 10
Input: Quantity = 15
Expected: Error "Insufficient stock. Available: 10, Required: 15"

Scenario: Sell exact amount
Stock: 10, Sell: 10
Expected: ✅ Stock becomes 0

Scenario: Negative inventory prevented
Expected: Never shows negative stock in UI
```

### **Test: Stock History**

**Steps:**
1. Go to Inventory Control → History tab
2. View all stock transactions

**Expected:**
- ✅ Shows all Stock IN records (↓ green)
- ✅ Shows all Stock OUT records (↑ red)
- ✅ Shows quantity, reason, timestamp
- ✅ Sorted by newest first

### **Test: Low Stock Alert**

**Steps:**
1. Set product stock to 3
2. Go to HomeScreen
3. Check dashboard metric "Low Stock"

**Expected:**
- ✅ Dashboard shows count = 1
- ✅ Product list shows "Low Stock" badge in orange
- ✅ Inventory Control → Low Stock tab lists it

---

## **4. Dashboard Testing**

### **Test: Metrics Display**

**Precondition:** Have 3 products with total stock 50

**Steps:**
1. Open HomeScreen
2. View dashboard cards

**Expected Metrics:**
- ✅ Total Products: 3
- ✅ Total Stock: 50 (sum of all products)
- ✅ Low Stock: count of products < 5
- ✅ Inventory Value: sum of (price × stock) for all products

**Example Calculation:**
```
Product 1: price=$10, stock=5  → value=$50
Product 2: price=$15, stock=10 → value=$150
Product 3: price=$5,  stock=35 → value=$175
Total Value: $375
```

### **Test: Dashboard Navigation**

**Steps:**
1. From HomeScreen, tap "Products"
2. Go back, tap "Inventory Control"
3. Go back to HomeScreen

**Expected:**
- ✅ All navigation works
- ✅ HomeScreen loads smoothly
- ✅ Metrics stay consistent

---

## **5. Data Persistence Testing**

### **Test: Offline Data**

**Steps:**
1. Add a product while online
2. Turn off network (airplane mode)
3. View products list

**Expected:**
- ✅ Products still visible
- ✅ Can perform searches
- ✅ SQLite provides offline access

### **Test: Data Survives App Restart**

**Steps:**
1. Add product: `Keyboard`, SKU: `KB-001`
2. Close app completely
3. Reopen app
4. Login again
5. Go to Products

**Expected:**
- ✅ Product still exists
- ✅ Stock quantity unchanged
- ✅ All details intact

### **Test: Database Integrity**

**Steps:**
1. Add product
2. Do Stock IN (add 10)
3. Do Stock OUT (remove 3)
4. Check stock = original + 10 - 3

**Expected:**
- ✅ Math correct
- ✅ History shows both transactions
- ✅ No data loss

---

## **6. Input Validation Testing**

### **Test: Email Validation**

| Input | Expected |
|-------|----------|
| empty | Error: "Email is required" |
| test | Error: "Please enter a valid email" |
| test@example | Error: "Please enter a valid email" |
| test@example.com | ✅ Valid |
| TEST@EXAMPLE.COM | ✅ Valid (case insensitive) |

### **Test: Password Validation**

| Input | Expected |
|-------|----------|
| empty | Error: "Password is required" |
| 12345 | Error: "must be at least 6" |
| 123456 | ✅ Valid |
| verylongpassword123 | ✅ Valid |

### **Test: Product Field Validation**

| Field | Invalid | Valid |
|-------|---------|-------|
| Name | "" | "Monitor" |
| SKU | "" | "MON-001" |
| Price | 0, -5, "abc" | 99.99, 0.01 |
| Cost | -5, "abc" | 45.50, 0 |
| Quantity | -1, "abc" | 0, 100 |

---

## **7. Error Handling Testing**

### **Test: Firebase Error**

**If Firebase credentials missing:**
- Expected: Crash on startup with clear error
- Solution: Update `firebase_options.dart`

### **Test: Database Error**

**Try to cause database error:**
1. Add product with 10,000 character name
2. Should handle gracefully or error with message

**Expected:**
- ✅ Error message shown
- ✅ App doesn't crash
- ✅ Can recover

### **Test: Network Error**

**Steps:**
1. Turn off internet
2. Try to login
3. Should show network error

**Expected:**
- ✅ Error: "Network error..."
- ✅ Can retry

---

## **8. UI/UX Testing**

### **Test: Responsive Layout**

- [ ] Screens work on phone (4.5" - 6")
- [ ] Text readable on all screen sizes
- [ ] Buttons easily tappable (48px minimum)
- [ ] No layout overflow

### **Test: Loading States**

- [ ] Shows spinner while loading
- [ ] Buttons disabled during operation
- [ ] Clear feedback on success/error

### **Test: Navigation**

- [ ] Back button works
- [ ] No dead-end screens
- [ ] Can reach all features from home

### **Test: Forms**

- [ ] All validators work
- [ ] Clear error messages
- [ ] Can edit after error
- [ ] Focus management (keyboard appears for inputs)

---

## **9. Performance Testing**

### **Test: List Performance**

**With 100 products:**
- [ ] ProductListScreen loads smoothly
- [ ] Scrolling is 60 FPS
- [ ] Search responds quickly

### **Test: Transaction Performance**

**With 1000 history records:**
- [ ] Stock IN/OUT completes < 1 second
- [ ] History loads smoothly
- [ ] No lag when viewing stock

---

## **10. Logout & Session Testing**

### **Test: Logout**

**Steps:**
1. From HomeScreen, tap menu → Logout
2. Should return to LoginScreen
3. Try to access products (can't)

**Expected:**
- ✅ Logged out completely
- ✅ Must login again to see products
- ✅ Data persisted for next login

### **Test: Session Persistence**

**Steps:**
1. Login
2. Kill app (force stop, not just backgrounded)
3. Reopen app

**Expected:**
- ✅ Still logged in
- ✅ Goes directly to HomeScreen
- ✅ Can access products without re-login

---

## **Test Summary Report**

| Feature | Tested | Passed | Notes |
|---------|--------|--------|-------|
| Sign Up | ☐ | ☐ | |
| Login | ☐ | ☐ | |
| Logout | ☐ | ☐ | |
| Add Product | ☐ | ☐ | |
| Edit Product | ☐ | ☐ | |
| Delete Product | ☐ | ☐ | |
| View Products | ☐ | ☐ | |
| Search Products | ☐ | ☐ | |
| Stock IN | ☐ | ☐ | |
| Stock OUT | ☐ | ☐ | |
| Stock History | ☐ | ☐ | |
| Low Stock Alert | ☐ | ☐ | |
| Dashboard | ☐ | ☐ | |
| Offline Mode | ☐ | ☐ | |
| Data Persistence | ☐ | ☐ | |

---

## **Bug Reporting Template**

If you find a bug:

```
Title: [Feature] Brief description

Steps to Reproduce:
1. ...
2. ...
3. ...

Expected: What should happen

Actual: What actually happens

Device: Android/iOS/Web
OS Version: 12.0
App Version: 1.0.0

Screenshots/Logs: (if applicable)
```

---

## **Acceptance Criteria**

✅ All authentication tests pass  
✅ All product CRUD tests pass  
✅ All stock operations work correctly  
✅ Low stock alerts functional  
✅ Data persists across app restarts  
✅ No crashes on error scenarios  
✅ All validations work  
✅ Navigation intuitive  
✅ Performance acceptable  
✅ Offline-first functionality works  

---

**See QUICKSTART.md for quick test workflow**
