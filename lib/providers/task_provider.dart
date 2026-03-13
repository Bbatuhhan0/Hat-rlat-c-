import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

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

  StreamSubscription<Position>? _positionStreamSubscription;
  final Map<String, bool> _notifiedTasks = {};

  TaskProvider() {
    _loadTasks();
    _loadTheme();
  }

  // --- Location logic ---
  void _checkLocationTracking() async {
    final hasLocationTasks = _tasks.any(
      (t) => !t.isCompleted && t.latitude != null && t.longitude != null,
    );

    if (hasLocationTasks) {
      if (_positionStreamSubscription == null) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }

        if (permission == LocationPermission.deniedForever) return;

        final locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // Trigger update every 100 meters
        );

        _positionStreamSubscription =
            Geolocator.getPositionStream(
              locationSettings: locationSettings,
            ).listen((Position position) {
              _checkDistanceLogic(position);
            });
      }
    } else {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    }
  }

  void _checkDistanceLogic(Position currentPosition) {
    final locationTasks = _tasks
        .where(
          (t) => !t.isCompleted && t.latitude != null && t.longitude != null,
        )
        .toList();

    for (var task in locationTasks) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        task.latitude!,
        task.longitude!,
      );

      if (distance <= (task.radius ?? 1000.0)) {
        if (_notifiedTasks[task.id] != true) {
          _notifiedTasks[task.id] = true;
          NotificationService().flutterLocalNotificationsPlugin.show(
            task.id.hashCode,
            'Hedefine yaklaştın: ${task.title}',
            'Mesafe onaylandı. Başlamak için iyi bir zaman!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'location_channel_id',
                'Location Reminders',
                channelDescription:
                    'Notifications for location-based reminders',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        }
      } else {
        _notifiedTasks[task.id] = false;
      }
    }
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
    double? latitude,
    double? longitude,
    double? radius,
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
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

        _tasks.add(newTask);
      }
    }

    if (!_categories.contains(category)) {
      _categories.add(category);
    }

    notifyListeners();
    await _saveTasks();
    _checkLocationTracking();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTasks();
    _checkLocationTracking();
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
    _checkLocationTracking();
  }

  Future<void> deleteAllTasksWithTitle(String title) async {
    // Tüm zamanlardan bu başlığa sahip tüm hedefleri siler
    _tasks.removeWhere((t) => t.title == title);
    notifyListeners();
    await _saveTasks();
    _checkLocationTracking();
  }

  Future<void> deleteTasksWithTitleInRange(
    String title,
    DateTime start,
    DateTime end,
  ) async {
    // Belirtilen tarih aralığındaki (başlangıç ve bitiş dahil) görevleri siler
    _tasks.removeWhere((t) {
      if (t.title != title) return false;
      // Start ve end tarihlerinin saat kısımlarını sıfırlayıp karşılaştırma yapalım
      final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      return taskDate.compareTo(startDate) >= 0 &&
          taskDate.compareTo(endDate) <= 0;
    });
    notifyListeners();
    await _saveTasks();
    _checkLocationTracking();
  }

  List<String> get uniqueTaskTitles {
    // Veritabanındaki tüm benzersiz görev başlıklarını döndürür
    return _tasks.map((t) => t.title).toSet().toList();
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      notifyListeners();
      await _saveTasks();
      _checkLocationTracking();
    }
  }

  Future<void> clearAllTasks() async {
    _tasks.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tasks_data_v3');
    notifyListeners();
    _checkLocationTracking();
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
    _checkLocationTracking();
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

  // --- Statistics Logic ---

  /// Returns total completed tasks in the last 7 days grouped by index (0=today, 1=yesterday... 6=6 days ago)
  Map<int, int> get weeklyCompletionStats {
    final Map<int, int> stats = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final completedCount = _tasks.where((t) {
        return t.isCompleted &&
            t.date.year == targetDate.year &&
            t.date.month == targetDate.month &&
            t.date.day == targetDate.day;
      }).length;
      stats[i] = completedCount;
    }
    return stats;
  }

  /// Calculates the completion rate (0.0 to 1.0) for the last 30 days. Key is 'days ago' (0 to 29).
  Map<int, double> get monthlyCompletionRates {
    final Map<int, double> stats = {};
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final dayTasks = _tasks.where(
        (t) =>
            t.date.year == targetDate.year &&
            t.date.month == targetDate.month &&
            t.date.day == targetDate.day,
      );

      if (dayTasks.isEmpty) {
        stats[i] = 0.0;
      } else {
        final completed = dayTasks.where((t) => t.isCompleted).length;
        stats[i] = completed / dayTasks.length;
      }
    }
    return stats;
  }

  /// Calculates distribution of completed tasks by category in the last 30 days
  Map<String, double> get monthlyCategoryStats {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentTasks = _tasks.where(
      (t) =>
          t.isCompleted &&
          t.date.isAfter(thirtyDaysAgo) &&
          t.date.isBefore(now.add(const Duration(days: 1))),
    );

    if (recentTasks.isEmpty) return {};

    final Map<String, int> counts = {};
    for (var task in recentTasks) {
      counts[task.title] = (counts[task.title] ?? 0) + 1;
    }

    final Map<String, double> percentages = {};
    final total = recentTasks.length;
    counts.forEach((key, value) {
      percentages[key] = value / total;
    });

    return percentages;
  }

  /// Finds the day of the week with the most completed tasks all time
  String get mostProductiveDay {
    final completedTasks = _tasks.where((t) => t.isCompleted);
    if (completedTasks.isEmpty) return 'Veri Yok';

    final Map<int, int> dayCounts = {};
    for (var task in completedTasks) {
      dayCounts[task.date.weekday] = (dayCounts[task.date.weekday] ?? 0) + 1;
    }

    int bestDay = 1;
    int maxCount = 0;

    dayCounts.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        bestDay = day;
      }
    });

    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[bestDay - 1]; // weekday is 1-7
  }

  /// Returns raw counts of top categories
  Map<String, int> get topCategories {
    final completedTasks = _tasks.where((t) => t.isCompleted);
    final Map<String, int> counts = {};

    for (var task in completedTasks) {
      counts[task.title] = (counts[task.title] ?? 0) + 1;
    }

    // Sort to return top 5
    var sortedKeys = counts.keys.toList(growable: false)
      ..sort((k1, k2) => counts[k2]!.compareTo(counts[k1]!));

    final Map<String, int> result = {};
    for (int i = 0; i < sortedKeys.length && i < 5; i++) {
      result[sortedKeys[i]] = counts[sortedKeys[i]]!;
    }

    return result;
  }

  String get dailyQuote => 'Harika bir gün!';

  Future<void> initNotificationService() async {}
}
