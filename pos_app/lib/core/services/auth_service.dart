/// Local Authentication Service
/// Handles user login, signup, and authentication state
/// Uses local storage (SQLite) for user credentials

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalUser {
  final String userId;
  final String email;

  LocalUser({required this.userId, required this.email});
}

class AuthService {
  static Database? _database;
  LocalUser? _currentUser;

  /// Gets the current authenticated user
  LocalUser? get currentUser => _currentUser;

  /// Checks if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Gets current user's UID
  String? get currentUserId => _currentUser?.userId;

  /// Stream of authentication state changes (emit null or user)
  Stream<LocalUser?> get authStateChanges async* {
    yield _currentUser;
  }

  /// Initialize the authentication database
  Future<void> _initDatabase() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pos_app_auth.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Sign up with email and password
  /// Throws exception on failure
  Future<LocalUser> signup({
    required String email,
    required String password,
  }) async {
    await _initDatabase();

    // Validate email and password
    if (email.isEmpty) throw 'Email cannot be empty';
    if (password.isEmpty) throw 'Password cannot be empty';
    if (password.length < 6) throw 'Password must be at least 6 characters';
    if (!email.contains('@')) throw 'Invalid email address';

    try {
      final db = _database!;
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      await db.insert('users', {
        'id': userId,
        'email': email,
        'password': password,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _currentUser = LocalUser(userId: userId, email: email);
      return _currentUser!;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw 'Email is already registered';
      }
      throw 'Signup failed: $e';
    }
  }

  /// Sign in with email and password
  /// Throws exception on failure
  Future<LocalUser> login({
    required String email,
    required String password,
  }) async {
    await _initDatabase();

    if (email.isEmpty) throw 'Email cannot be empty';
    if (password.isEmpty) throw 'Password cannot be empty';

    try {
      final db = _database!;
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (results.isEmpty) {
        throw 'No user found with this email';
      }

      final user = results.first;
      if (user['password'] != password) {
        throw 'Wrong password provided';
      }

      _currentUser = LocalUser(
        userId: user['id'] as String,
        email: user['email'] as String,
      );
      return _currentUser!;
    } catch (e) {
      if (e.toString().startsWith('No user found') ||
          e.toString().startsWith('Wrong password')) {
        throw e.toString();
      }
      throw 'Login failed: $e';
    }
  }

  /// Sign out the current user
  Future<void> logout() async {
    _currentUser = null;
  }
}
