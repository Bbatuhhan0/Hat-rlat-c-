import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  final List<String> _categories = [];
  List<String> get categories => _categories;

  // UI State
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  TaskProvider() {
    _loadTasks();
    _loadTheme();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // --- Core Actions ---

  Future<void> addTask({
    required String title,
    required DateTime date,
    required List<String> times, // List of "HH:mm" strings
    String? notes,
    required int colorValue,
    required String category,
    bool isBulk = false,
    String repetitionType = 'none', // 'daily', 'monthly', 'yearly', 'none'
  }) async {
    final now = DateTime.now();

    // Determine the range of dates based on repetitionType
    List<DateTime> targetDates = [date]; // Always include the selected date

    if (isBulk) {
      if (repetitionType == 'daily') {
        // "Her Gün" -> 1 Yıl (365 gün) boyunca her güne ekle
        for (int i = 1; i <= 365; i++) {
          targetDates.add(DateTime(date.year, date.month, date.day + i));
        }
      } else if (repetitionType == 'monthly') {
        // Add for the remaining days of the current month
        int i = 1;
        while (true) {
          DateTime nextDate = DateTime(date.year, date.month, date.day + i);
          if (nextDate.month != date.month) break;
          targetDates.add(nextDate);
          i++;
        }
      } else if (repetitionType == 'yearly') {
        // Add for the remaining days of the current year
        int i = 1;
        while (true) {
          DateTime nextDate = DateTime(date.year, date.month, date.day + i);
          if (nextDate.year != date.year) break;
          targetDates.add(nextDate);
          i++;
        }
      }
    }

    // Create Tasks for ALL combinations of (Times x Dates)
    // To ensure unique ID: timestamp + index is good, but in a tight loop it might duplicate if not careful.
    // We will use a counter.
    int counter = 0;
    final baseId = now.microsecondsSinceEpoch;

    for (var d in targetDates) {
      for (var t in times) {
        counter++;
        // Guaranteed unique ID per task instance
        final String uniqueId = '${baseId}_$counter';

        final newTask = Task(
          id: uniqueId,
          title: title,
          notes: notes,
          date: d,
          time: t,
          colorValue: colorValue,
          category: category,
          isBulk: isBulk,
          isCompleted: false,
        );

        _tasks.add(newTask);
      }
    }

    if (!_categories.contains(category)) {
      _categories.add(category);
    }

    notifyListeners();
    await _saveTasks();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTasks();
  }

  Future<void> deleteTaskSeries(String title, DateTime date) async {
    // Deletes all tasks with the same title on the same date
    _tasks.removeWhere(
      (t) =>
          t.title == title &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day,
    );
    notifyListeners();
    await _saveTasks();
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> clearAllTasks() async {
    _tasks.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tasks_data_v3');
    notifyListeners();
  }

  // Statistics

  // Formula: (Completed / Total) * 100
  double get completionRate {
    final dailyTasks = tasksForSelectedDate;
    if (dailyTasks.isEmpty) return 0.0;

    final completedCount = dailyTasks.where((t) => t.isCompleted).length;
    return (completedCount / dailyTasks.length) * 100;
  }

  // Getter for UI (0.0 - 1.0)
  double get dailyCompletionRatio {
    if (tasksForSelectedDate.isEmpty) return 0.0;
    return completionRate / 100;
  }

  List<Task> get tasksForSelectedDate {
    return _tasks.where((t) {
      return t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month &&
          t.date.day == _selectedDate.day;
    }).toList();
  }

  // --- Persistence ---

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedData = _tasks
        .map((task) => task.toJson())
        .toList();
    await prefs.setStringList(
      'tasks_data_v3',
      encodedData,
    ); // Bump version to v3
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedData = prefs.getStringList('tasks_data_v3');

    if (encodedData != null) {
      _tasks = encodedData.map((item) => Task.fromJson(item)).toList();
    }
    notifyListeners();
  }

  // Theme
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('theme_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_mode', _isDarkMode);
  }

  // Placeholders for stats page
  Map<int, double> get weeklyCompletionRates => {};
  Map<int, double> get monthlyCompletionRates => {};
  Map<String, double> get monthlyCategoryStats => {};
  String get mostProductiveDay => 'Veri Yok';
  Map<String, int> get topCategories => {};
  String get dailyQuote => 'Harika bir gün!';
  Map<int, int> get weeklyCompletionStats => {};

  Future<void> initNotificationService() async {}
}
