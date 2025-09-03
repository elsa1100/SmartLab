import 'dart:io'; // <--- Add this for file operations
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, 'users.db');
    print("Database Path: $dbPath");

    if (await databaseExists(dbPath)) {
      print("Old database found, deleting it to recreate tables.");
      await deleteDatabase(dbPath);
    }

    return await openDatabase(
      dbPath,
      version: 5, // Database version
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Create tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        age INTEGER NOT NULL
      )
    ''');

    await db.execute(''' 
      CREATE TABLE analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        test_name TEXT NOT NULL,
        analysis_text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE
      )
    ''');

    print("Database created with tables: users, analyses");
  }

  // Handle database upgrades
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");

    if (oldVersion < 5) {
      print("Upgrading to version 5: creating analyses table.");
      await db.execute('''
      CREATE TABLE IF NOT EXISTS analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        test_name TEXT NOT NULL,
        analysis_text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE
      )
    ''');
    }
  }

  // --- (All your existing methods remain exactly the same) ---

  Future<int> registerUser(String name, String username, String email, String password, int age) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'username = ? OR email = ?',
        whereArgs: [username, email],
      );
      if (result.isNotEmpty) {
        print("User with the same username or email already exists.");
        return -1;
      }

      return await db.insert('users', {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'age': age,
      });
    } catch (e) {
      print("Error during registration: $e");
      return -1;
    }
  }

  Future<bool> loginUser(String username, String password) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isEmpty) {
      print("Login failed for username: $username");
    }
    return result.isNotEmpty;
  }

  Future<String> getUserName(String username) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['name'],
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first['name'] as String : "User";
  }

  Future<int> insertAnalysis(String username, String testName, String analysisText) async {
    final db = await database;
    try {
      return await db.insert(
        'analyses',
        {
          'username': username,
          'test_name': testName,
          'analysis_text': analysisText,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print("Error inserting analysis: $e");
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getUserAnalyses(String username) async {
    final db = await database;
    return await db.query(
      'analyses',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> deleteAnalysis(int id) async {
    final db = await database;
    return await db.delete(
      'analyses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(String username) async {
    final db = await database;
    try {
      int result = await db.delete(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      print("Deleted $result user(s)");
      return result;
    } catch (e) {
      print("Error deleting user: $e");
      return 0;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  Future<String?> getUserEmail(String username) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> result = await db.query(
        'users',
        columns: ['email'],
        where: 'username = ?',
        whereArgs: [username],
      );
      if (result.isNotEmpty) {
        return result.first['email'] as String;
      } else {
        print("No user found with username: $username");
        return null;
      }
    } catch (e) {
      print("Error fetching email for user $username: $e");
      return null;
    }
  }

  Future<int> updateUser(
      String username, String name, String email, String password, int age) async {
    final db = await database;

    try {
      List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ? AND username != ?',
        whereArgs: [email, username],
      );
      if (result.isNotEmpty) {
        print("Email already in use by another user: $email");
        return 0;
      }

      int resultUpdate = await db.update(
        'users',
        {
          'name': name,
          'email': email,
          'password': password,
          'age': age,
        },
        where: 'username = ?',
        whereArgs: [username],
      );

      print("Updated $resultUpdate user(s)");
      return resultUpdate;
    } catch (e) {
      print("Error updating user info: $e");
      return 0;
    }
  }
}
