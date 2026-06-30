import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        isRepeating INTEGER NOT NULL,
        repeatDays TEXT,
        reminderDateTime TEXT,
        dueNotificationId INTEGER,
        reminderNotificationId INTEGER,
        imagePaths TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration from v1/v2 to v2/v3: add new columns
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN reminderDateTime TEXT');
        await db.execute('ALTER TABLE tasks ADD COLUMN dueNotificationId INTEGER');
        await db.execute('ALTER TABLE tasks ADD COLUMN reminderNotificationId INTEGER');
      } catch (e) {
        // ignore if columns already exist
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN imagePaths TEXT');
      } catch (e) {
        // ignore if column already exists
      }
    }
  }

  // CRUD operations for tasks
  Future<Task> createTask(Task task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<Task?> readTask(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      columns: ['id', 'title', 'description', 'dueDate', 'isCompleted', 'isRepeating', 'repeatDays', 'reminderDateTime', 'dueNotificationId', 'reminderNotificationId', 'imagePaths'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> readTodayTasks() async {
    final db = await instance.database;
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);

    final result = await db.query(
      'tasks',
      where: "date(dueDate) = ?",
      whereArgs: [todayStr],
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> readCompletedTasks() async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: "isCompleted = ?",
      whereArgs: [1],
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> readRepeatingTasks() async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: "isRepeating = ?",
      whereArgs: [1],
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for subtasks
  Future<SubTask> createSubTask(SubTask subtask) async {
    final db = await instance.database;
    final id = await db.insert('subtasks', subtask.toMap());
    return subtask.copyWith(id: id);
  }

  Future<List<SubTask>> readTaskSubTasks(int taskId) async {
    final db = await instance.database;
    final result = await db.query(
      'subtasks',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );

    return result.map((map) => SubTask.fromMap(map)).toList();
  }

  Future<int> updateSubTask(SubTask subtask) async {
    final db = await instance.database;
    return db.update(
      'subtasks',
      subtask.toMap(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  Future<int> deleteSubTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'subtasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}