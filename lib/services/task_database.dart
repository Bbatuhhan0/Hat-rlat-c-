import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskDatabase {
  static final TaskDatabase instance = TaskDatabase._init();
  static Database? _database;

  TaskDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks_db_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
  }

  Future<List<Task>> loadAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    
    // Check if we need to migrate from SharedPreferences
    if (result.isEmpty) {
      return await _migrateFromSharedPreferences();
    }

    return result.map((json) => Task.fromJson(json['data'] as String)).toList();
  }

  Future<List<Task>> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedData = prefs.getStringList('tasks_data_v3');
    
    if (encodedData != null && encodedData.isNotEmpty) {
      final tasks = encodedData.map((item) => Task.fromJson(item)).toList();
      await insertTasks(tasks);
      return tasks;
    }
    return [];
  }

  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert(
      'tasks',
      {'id': task.id, 'data': task.toJson()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTasks(List<Task> tasks) async {
    final db = await instance.database;
    var batch = db.batch();
    for (var task in tasks) {
      batch.insert(
        'tasks',
        {'id': task.id, 'data': task.toJson()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateTask(Task task) async {
    final db = await instance.database;
    await db.update(
      'tasks',
      {'data': task.toJson()},
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await instance.database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTasks(List<String> ids) async {
    final db = await instance.database;
    var batch = db.batch();
    for (var id in ids) {
      batch.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('tasks');
  }
}
