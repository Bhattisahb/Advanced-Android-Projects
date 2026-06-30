import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = 'smartstock.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'products';

  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        last7DaysSales TEXT NOT NULL,
        currentStock INTEGER NOT NULL,
        minimumThreshold INTEGER NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // Insert or update a product
  Future<int> saveProduct({
    required String name,
    required List<int> last7DaysSales,
    required int currentStock,
    required int minimumThreshold,
    required double costPrice,
    required double sellingPrice,
  }) async {
    final db = await database;
    
    final sales = last7DaysSales.join(',');
    
    // Check if product exists
    final existing = await db.query(
      _tableName,
      where: 'name = ?',
      whereArgs: [name],
    );
    
    if (existing.isNotEmpty) {
      // Update existing product
      return await db.update(
        _tableName,
        {
          'name': name,
          'last7DaysSales': sales,
          'currentStock': currentStock,
          'minimumThreshold': minimumThreshold,
          'costPrice': costPrice,
          'sellingPrice': sellingPrice,
        },
        where: 'name = ?',
        whereArgs: [name],
      );
    } else {
      // Insert new product
      return await db.insert(_tableName, {
        'name': name,
        'last7DaysSales': sales,
        'currentStock': currentStock,
        'minimumThreshold': minimumThreshold,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
      });
    }
  }

  // Get all products
  Future<Map<String, Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    final results = await db.query(_tableName);
    
    final products = <String, Map<String, dynamic>>{};
    
    for (final row in results) {
      final name = row['name'] as String;
      final salesString = row['last7DaysSales'] as String;
      final last7DaysSales = salesString
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
      
      products[name] = {
        'last7DaysSales': last7DaysSales,
        'currentStock': row['currentStock'] as int,
        'minimumThreshold': row['minimumThreshold'] as int,
        'costPrice': row['costPrice'] as double,
        'sellingPrice': row['sellingPrice'] as double,
      };
    }
    
    return products;
  }

  // Delete a product
  Future<int> deleteProduct(String name) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  // Get product by name
  Future<Map<String, dynamic>?> getProduct(String name) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      where: 'name = ?',
      whereArgs: [name],
    );
    
    if (results.isEmpty) return null;
    
    final row = results.first;
    final salesString = row['last7DaysSales'] as String;
    final last7DaysSales = salesString
        .split(',')
        .map((e) => int.parse(e.trim()))
        .toList();
    
    return {
      'last7DaysSales': last7DaysSales,
      'currentStock': row['currentStock'] as int,
      'minimumThreshold': row['minimumThreshold'] as int,
      'costPrice': row['costPrice'] as double,
      'sellingPrice': row['sellingPrice'] as double,
    };
  }

  // Clear all products (for testing)
  Future<void> clearAllProducts() async {
    final db = await database;
    await db.delete(_tableName);
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
