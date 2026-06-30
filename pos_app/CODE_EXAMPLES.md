## Code Examples & Documentation

This document explains how key parts of the code work with examples.

---

## **1. Authentication Flow**

### **How Login Works**

```dart
// lib/ui/auth/login_screen.dart

class LoginScreen extends StatelessWidget {
  // When user taps "Login" button
  Future<void> _handleLogin() async {
    // 1. Get AuthService from Provider
    final authService = context.read<AuthService>();
    
    // 2. Call Firebase login
    await authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    
    // 3. Firebase returns User object or throws exception
    // 4. If successful, _AuthWrapper detects user logged in
    // 5. Navigation to HomeScreen happens automatically
  }
}
```

### **Authentication State Management**

```dart
// lib/main.dart - _AuthWrapper

class _AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Listen to Firebase auth state changes
    return StreamBuilder(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        // No user → Show LoginScreen
        // User logged in → Show HomeScreen
        // Waiting → Show loading spinner
      },
    );
  }
}
```

**Key Point**: No manual routing needed! Stream automatically handles navigation.

---

## **2. Product Management**

### **Adding a Product**

```dart
// lib/data/repositories/product_repository.dart

Future<int> addProduct({
  required String name,
  required String sku,
  required double price,
  required double cost,
  required String category,
  required int stockQuantity,
}) async {
  // 1. Validate input
  if (name.isEmpty || sku.isEmpty) {
    throw Exception('Name and SKU required');
  }
  
  // 2. Check SKU uniqueness
  final existing = await _productDao.getProductBySku(sku);
  if (existing != null) {
    throw Exception('SKU already exists');
  }
  
  // 3. Create Product object
  final product = Product(
    name: name,
    sku: sku,
    price: price,
    cost: cost,
    category: category,
    stockQuantity: stockQuantity,
    createdAt: DateTime.now(),
  );
  
  // 4. Save to SQLite
  return _productDao.insertProduct(product);
}
```

### **Flow Diagram**

```
ProductFormScreen
  ↓ (calls)
ProductRepository.addProduct()
  ↓ (validates)
ProductDao.insertProduct()
  ↓ (saves)
SQLite Database
  ↓ (returns)
ProductListScreen (reloads via Future)
```

---

## **3. Stock Management with Transactions**

### **Stock IN Transaction**

```dart
// lib/data/repositories/inventory_repository.dart

Future<void> addStockIn({
  required int productId,
  required int quantity,
  String? reason,
}) async {
  // TRANSACTION: Both operations succeed or both fail
  await _dbHelper.transaction((txn) async {
    // 1. Get current product
    final product = await _productDao.getProductById(productId);
    
    // 2. Update stock
    await txn.update(
      'products',
      {
        'stockQuantity': product.stockQuantity + quantity,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
    
    // 3. Record history
    final history = StockHistory(
      productId: productId,
      changeType: StockChangeType.stockIn,
      quantity: quantity,
      reason: reason,
      timestamp: DateTime.now(),
    );
    await txn.insert('stock_history', history.toJson());
  });
}
```

**Why Transaction?**
- If product update fails, history isn't recorded
- If history fails, product stock isn't updated
- Prevents inconsistent database state

### **Stock OUT with Validation**

```dart
Future<void> addStockOut({
  required int productId,
  required int quantity,
}) async {
  // ... transaction starts ...
  
  final product = await _productDao.getProductById(productId);
  
  // VALIDATE: Prevent overselling
  if (product.stockQuantity < quantity) {
    throw Exception(
      'Not enough stock. Have: ${product.stockQuantity}, Need: $quantity'
    );
  }
  
  // Continue with transaction...
}
```

---

## **4. Database Layer**

### **ProductDao - CRUD Operations**

```dart
// lib/data/local/product_dao.dart

class ProductDao {
  // CREATE
  Future<int> insertProduct(Product product) async {
    return db.insert('products', product.toJson());
  }
  
  // READ
  Future<Product?> getProductById(int id) async {
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isEmpty ? null : Product.fromJson(result.first);
  }
  
  // UPDATE
  Future<int> updateProduct(Product product) async {
    return db.update(
      'products',
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }
  
  // DELETE
  Future<int> deleteProduct(int id) async {
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
```

### **Searching Products**

```dart
// Case-insensitive search
Future<List<Product>> searchProducts(String query) async {
  return db.query(
    'products',
    where: 'LOWER(name) LIKE ? OR LOWER(sku) LIKE ?',
    whereArgs: ['%${query.toLowerCase()}%', '%${query.toLowerCase()}%'],
  );
}
```

---

## **5. UI Patterns**

### **FutureBuilder Pattern**

```dart
// lib/ui/products/product_list_screen.dart

@override
Widget build(BuildContext context) {
  return FutureBuilder<List<Product>>(
    future: _productRepository.getAllProducts(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
      
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }
      
      final products = snapshot.data ?? [];
      return ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ProductTile(products[index]),
      );
    },
  );
}
```

### **Search with Real-time Filter**

```dart
// User types in search field
_searchController.addListener(() {
  final query = _searchController.text;
  
  // Filter locally (no database query on every keystroke)
  setState(() {
    _filteredProducts = _products
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  });
});
```

### **Dialog for User Input**

```dart
// Confirm deletion
final confirm = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Delete?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Delete'),
      ),
    ],
  ),
);

if (confirm == true) {
  // User confirmed
}
```

---

## **6. Input Validation**

### **Validator Functions**

```dart
// lib/core/utils/validators.dart

static String? validateEmail(String? value) {
  if (value?.isEmpty ?? true) return 'Email required';
  
  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!regex.hasMatch(value!)) return 'Invalid email';
  
  return null; // Valid
}

static String? validatePrice(String? value) {
  if (value?.isEmpty ?? true) return 'Price required';
  
  final price = double.tryParse(value!);
  if (price == null || price <= 0) {
    return 'Must be > 0';
  }
  
  return null; // Valid
}
```

### **Using Validators in Form**

```dart
TextFormField(
  controller: _priceController,
  validator: Validators.validatePrice, // Uses validator above
)
```

---

## **7. Error Handling**

### **Try-Catch Pattern**

```dart
Future<void> _handleSave() async {
  setState(() => _isLoading = true);
  
  try {
    // Attempt operation
    await _repository.addProduct(...);
    
    // Success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added!')),
    );
    
    // Navigate back
    Navigator.pop(context);
    
  } catch (e) {
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### **Firebase Error Parsing**

```dart
// lib/core/services/auth_service.dart

String _parseAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No account with this email';
    case 'wrong-password':
      return 'Incorrect password';
    case 'email-already-in-use':
      return 'Email already registered';
    default:
      return 'Authentication failed';
  }
}
```

---

## **8. Navigation Patterns**

### **Named Routes**

```dart
// lib/main.dart
routes: {
  AppConstants.ROUTE_LOGIN: (_) => const LoginScreen(),
  AppConstants.ROUTE_HOME: (_) => const HomeScreen(),
  AppConstants.ROUTE_PRODUCTS: (_) => const ProductListScreen(),
}

// Navigate
Navigator.pushNamed(context, AppConstants.ROUTE_HOME);
Navigator.pushReplacementNamed(context, AppConstants.ROUTE_LOGIN);
```

### **Passing Arguments**

```dart
// Navigate with argument
Navigator.pushNamed(
  context,
  AppConstants.ROUTE_PRODUCT_FORM,
  arguments: product,
);

// Receive argument
final product = ModalRoute.of(context)?.settings.arguments as Product?;
```

---

## **9. Low Stock Alert System**

### **Check if Product is Low Stock**

```dart
// lib/data/models/product_model.dart

bool get isLowStock {
  return stockQuantity < AppConstants.LOW_STOCK_THRESHOLD;
}
```

### **Get All Low Stock Products**

```dart
// lib/data/repositories/product_repository.dart

Future<List<Product>> getLowStockProducts() async {
  return _productDao.getLowStockProducts(
    AppConstants.LOW_STOCK_THRESHOLD,
  );
}
```

### **Display Warning UI**

```dart
// If product is low stock, show orange badge
if (product.isLowStock) {
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.shade100,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text('Low Stock', style: TextStyle(color: Colors.orange)),
  );
}
```

---

## **10. Model Serialization**

### **Convert Object ↔ JSON**

```dart
// lib/data/models/product_model.dart

class Product {
  // To JSON (for database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // From JSON (from database)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

### **Usage**

```dart
// Save to database
final json = product.toJson();
await db.insert('products', json);

// Read from database
final rows = await db.query('products');
final products = rows.map((row) => Product.fromJson(row)).toList();
```

---

## **11. Profit Margin Calculation**

```dart
// In Product model
double get profitMargin {
  if (price == 0) return 0;
  return ((price - cost) / price) * 100;
}

// Usage
Text('Margin: ${product.profitMargin.toStringAsFixed(1)}%')
```

---

## **12. Dashboard Metrics**

```dart
// lib/ui/shared/home_screen.dart

Future<Map<String, dynamic>> _loadDashboardData() async {
  final allProducts = await _productRepository.getAllProducts();
  final lowStockProducts = await _productRepository.getLowStockProducts();
  
  // Calculate metrics
  return {
    'totalProducts': allProducts.length,
    'lowStockCount': lowStockProducts.length,
    'totalInventoryValue': allProducts.fold(
      0,
      (sum, p) => sum + (p.price * p.stockQuantity),
    ),
    'totalStock': allProducts.fold(0, (sum, p) => sum + p.stockQuantity),
  };
}
```

---

## **Offline-First Strategy**

```
User Action
  ↓
Check SQLite (instant response)
  ↓
Update SQLite locally
  ↓
Queue for Firebase sync (when online)
  ↓
[Future] Sync to Firebase
```

All data is stored in SQLite first. Firebase sync happens in background when online.

---

## **Architecture Benefits**

✅ **Offline-First**: Works without internet  
✅ **Modular**: Easy to test and modify  
✅ **Transactions**: Data consistency guaranteed  
✅ **Validation**: Errors caught early  
✅ **Scalable**: Easy to add features  
✅ **Maintainable**: Clear separation of concerns  

---

**See ARCHITECTURE.md for full system design**
