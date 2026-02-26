import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';

// Legacy DatabaseHelper - Stubbed to preventing compilation errors.
// This is no longer used as we switched to SharedPreferences.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<Database> get database async {
    throw UnimplementedError();
  }

  Future<Task> create(Task task) async {
    throw UnimplementedError();
  }

  Future<Task> readTask(String id) async {
    // Changed to String to match Model
    throw UnimplementedError();
  }

  Future<List<Task>> readAllTasks() async {
    return [];
  }

  Future<int> update(Task task) async {
    return 0;
  }

  Future<int> delete(String id) async {
    // Changed to String
    return 0;
  }

  Future<int> deleteAll() async {
    return 0;
  }
}
