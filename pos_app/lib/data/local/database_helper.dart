/// Database Helper
/// Manages SQLite database initialization, schema creation, and connections
/// Singleton pattern ensures single database instance throughout app lifecycle

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pos_app/core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  /// Get or initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Database initialization timeout - check table schemas');
      },
    );
    return _database!;
  }

  /// Initialize SQLite database and create tables
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.DATABASE_NAME);

    return openDatabase(
      path,
      version: AppConstants.DATABASE_VERSION,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Enable foreign key support for referential integrity
        await db.execute('PRAGMA foreign_keys = ON');
        print('✓ Database opened successfully with foreign keys enabled');
      },
    );
  }

  /// Create database tables on first initialization
  Future<void> _createTables(Database db, int version) async {
    // Use the common table creation function
    await _createAllTables(db);
  }

  /// Handle database upgrades for future schema changes
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('🔄 Upgrading database from v$oldVersion to v$newVersion...');
    
    try {
      // For any upgrade, first ensure the type column exists in ledger_entries
      if (oldVersion < 4) {
        print('📝 Adding missing type column to ledger_entries...');
        try {
          // Check if column exists by trying to query it
          await db.rawQuery('SELECT type FROM ledger_entries LIMIT 1');
        } catch (e) {
          // Column doesn't exist, add it
          if (e.toString().contains('no such column')) {
            print('   Column missing, attempting ALTER TABLE...');
            await db.execute('''
              ALTER TABLE ledger_entries ADD COLUMN type TEXT DEFAULT 'DEBIT'
            ''');
            print('   ✓ Added type column');
          } else {
            print('   ⚠️ Unexpected error: $e');
          }
        }
      }
      
      // For any upgrade to v5 or later, ensure all tables exist
      if (oldVersion < 5) {
        print('🔄 Ensuring all tables exist with current schema...');
        await _createAllTables(db);
      }
      
      print('✓ Database upgrade complete (now v$newVersion)');
    } catch (e) {
      print('❌ Database upgrade error: $e');
      rethrow;
    }
  }

  /// Create all tables (used by both onCreate and onUpgrade)
  Future<void> _createAllTables(Database db) async {
    // Products table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
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
    ''');
    print('✓ Products table ready');

    // Stock history table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        changeType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');
    print('✓ Stock history table ready');

    // Customers table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        type TEXT NOT NULL DEFAULT 'WALK_IN',
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    print('✓ Customers table ready');

    // Sales table - CRITICAL: Must have synced column
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        subtotal REAL NOT NULL,
        discountAmount REAL NOT NULL DEFAULT 0,
        discountPercentage REAL NOT NULL DEFAULT 0,
        taxAmount REAL NOT NULL DEFAULT 0,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'COMPLETED',
        paymentMethod TEXT NOT NULL DEFAULT 'CASH',
        synced INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (customerId) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');
    print('✓ Sales table ready');

    // Sale items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        productSku TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        lineTotal REAL NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
    print('✓ Sale items table ready');

    // Ledger entries table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ledger_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        saleId INTEGER,
        description TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers(id) ON DELETE CASCADE,
        FOREIGN KEY (saleId) REFERENCES sales(id) ON DELETE SET NULL
      )
    ''');
    print('✓ Ledger entries table ready');

    // Create indexes for faster queries
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_history_productId ON stock_history(productId)');
    } catch (e) {
      print('⚠️ Index creation skipped: $e');
    }
    
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_customerId ON sales(customerId)');
    } catch (e) {
      print('⚠️ Index creation skipped: $e');
    }
    
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_createdAt ON sales(createdAt)');
    } catch (e) {
      print('⚠️ Index creation skipped: $e');
    }
    
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_saleId ON sale_items(saleId)');
    } catch (e) {
      print('⚠️ Index creation skipped: $e');
    }
    
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_entries_customerId ON ledger_entries(customerId)');
    } catch (e) {
      print('⚠️ Index creation skipped: $e');
    }
    print('✓ All indexes created');
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Execute a transaction with multiple operations
  /// Ensures atomicity - all operations succeed or all fail
  Future<T> transaction<T>(Future<T> Function(Transaction) action) async {
    final db = await database;
    return db.transaction(action);
  }
}
