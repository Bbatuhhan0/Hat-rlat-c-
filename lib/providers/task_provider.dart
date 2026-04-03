import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/task_model.dart';
import '../models/saved_location.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';

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

  // Saved Locations
  List<SavedLocation> _savedLocations = [];
  List<SavedLocation> get savedLocations => _savedLocations;

  // Settings
  bool _is24HourFormat = true;
  bool get is24HourFormat => _is24HourFormat;

  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;

  bool _isNotificationEnabled = true;
  bool get isNotificationEnabled => _isNotificationEnabled;

  bool _isNotificationSound = true;
  bool get isNotificationSound => _isNotificationSound;

  bool _isNotificationVibration = true;
  bool get isNotificationVibration => _isNotificationVibration;

  TaskProvider() {
    _loadTasks();
    _loadSettings();
  }

  // --- Location logic ---
  void _checkLocationTracking() {
    checkAndToggleService();
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
    bool isLocationTask = false,
    bool isSafeExitTask = false,
    String? locationName,
    List<int>? selectedWeekdays,
    List<DateTime>? specificDates,
    String? startTime,
    String? endTime,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    final now = DateTime.now();

    // Determine the range of dates based on repetitionType
    List<DateTime> targetDates = [date]; // Always include the selected date

    if (specificDates != null && specificDates.isNotEmpty) {
      targetDates = List.from(specificDates);
    } else if (isBulk) {
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
      if (selectedWeekdays != null && !selectedWeekdays.contains(d.weekday)) {
        continue;
      }
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
          isLocationTask: isLocationTask,
          isSafeExitTask: isSafeExitTask,
          locationName: locationName,
          startTime: startTime,
          endTime: endTime,
          isCompleted: false,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

        _tasks.add(newTask);

        // Schedule notification (Konumlu görev değilse saatli bildirim kur)
        if (!isLocationTask) {
          try {
            final timeParts = t.split(':');
            if (timeParts.length == 2) {
              final int hour = int.parse(timeParts[0]);
              final int minute = int.parse(timeParts[1]);
              final scheduledDateTime = DateTime(
                d.year,
                d.month,
                d.day,
                hour,
                minute,
              );

              final now = DateTime.now();
              final difference = scheduledDateTime.difference(now);

              // Eğer ayarlarda bildirimler kapalıysa hiç kurma
              if (_isNotificationEnabled) {
                if (difference.inSeconds > 0) {
                  NotificationService().scheduleNotification(
                    id: uniqueId.hashCode.abs(),
                    title: 'Hedef Zamanı: $title',
                    body: notes?.isNotEmpty == true
                        ? notes!
                        : 'Planladığın görevi yapma vakti geldi.',
                    scheduledDate: scheduledDateTime,
                    playSound: _isNotificationSound,
                    enableVibration: _isNotificationVibration,
                  );
                } else if (difference.inSeconds > -60 &&
                    difference.inSeconds <= 0) {
                  NotificationService().flutterLocalNotificationsPlugin.show(
                    uniqueId.hashCode.abs(),
                    'Hedef Zamanı: $title',
                    notes?.isNotEmpty == true
                        ? notes!
                        : 'Planladığın görevi yapma vakti geldi.',
                    NotificationDetails(
                      android: AndroidNotificationDetails(
                        'task_channel_id',
                        'Task Reminders',
                        channelDescription: 'Notifications for task reminders',
                        importance: Importance.max,
                        priority: Priority.high,
                        playSound: _isNotificationSound,
                        enableVibration: _isNotificationVibration,
                      ),
                      iOS: DarwinNotificationDetails(
                        presentSound: _isNotificationSound,
                      ),
                    ),
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('Notification schedule error: $e');
          }
        }
      }
    }

    if (!_categories.contains(category)) {
      _categories.add(category);
    }

    notifyListeners();
    await _saveTasks();
    _checkLocationTracking();

    if (isLocationTask) {
      final service = FlutterBackgroundService();
      if (!(await service.isRunning())) {
        service.startService();
      } else {
        service.invoke('check_location');
      }
    }
  }

  Future<void> deleteTask(String id) async {
    NotificationService().cancelNotification(id.hashCode.abs());
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTasks();
    _checkLocationTracking();
  }

  Future<void> deleteTaskSeries(String title, DateTime date) async {
    // Deletes all tasks with the same title on the same date
    final tasksToRemove = _tasks
        .where(
          (t) =>
              t.title == title &&
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day,
        )
        .toList();
    for (var t in tasksToRemove) {
      NotificationService().cancelNotification(t.id.hashCode.abs());
      _tasks.remove(t);
    }
    notifyListeners();
    await _saveTasks();
    _checkLocationTracking();
  }

  Future<void> deleteAllTasksWithTitle(String title) async {
    // Tüm zamanlardan bu başlığa sahip tüm hedefleri siler
    final tasksToRemove = _tasks.where((t) => t.title == title).toList();
    for (var t in tasksToRemove) {
      NotificationService().cancelNotification(t.id.hashCode.abs());
      _tasks.remove(t);
    }
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
    final tasksToRemove = _tasks.where((t) {
      if (t.title != title) return false;
      // Start ve end tarihlerinin saat kısımlarını sıfırlayıp karşılaştırma yapalım
      final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      return taskDate.compareTo(startDate) >= 0 &&
          taskDate.compareTo(endDate) <= 0;
    }).toList();
    for (var t in tasksToRemove) {
      NotificationService().cancelNotification(t.id.hashCode.abs());
      _tasks.remove(t);
    }
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
      final isNowCompleted = !task.isCompleted;
      _tasks[index] = task.copyWith(isCompleted: isNowCompleted);

      if (isNowCompleted) {
        NotificationService().cancelNotification(task.id.hashCode.abs());
      } else {
        // Reschedule if it's in the future
        try {
          final timeParts = task.time.split(':');
          if (timeParts.length == 2) {
            final int hour = int.parse(timeParts[0]);
            final int minute = int.parse(timeParts[1]);
            final scheduledDateTime = DateTime(
              task.date.year,
              task.date.month,
              task.date.day,
              hour,
              minute,
            );

            if (scheduledDateTime.isAfter(DateTime.now()) &&
                _isNotificationEnabled) {
              NotificationService().scheduleNotification(
                id: task.id.hashCode.abs(),
                title: 'Hedef Zamanı: ${task.title}',
                body: task.notes?.isNotEmpty == true
                    ? task.notes!
                    : 'Planladığın görevi yapma vakti geldi.',
                scheduledDate: scheduledDateTime,
                playSound: _isNotificationSound,
                enableVibration: _isNotificationVibration,
              );
            }
          }
        } catch (e) {
          debugPrint('Reschedule error: $e');
        }
      }

      notifyListeners();
      await _saveTasks();
      _checkLocationTracking();
    }
  }

  Future<void> clearAllTasks() async {
    NotificationService().cancelAllNotifications();
    _tasks.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tasks_data_v3');
    notifyListeners();
    _checkLocationTracking();
  }

  // Statistics

  // Helper getter to filter out Location and Exit Reminders from statistics globally
  List<Task> get _statisticalTasks => _tasks.where((t) => !t.isLocationTask && !t.isSafeExitTask).toList();

  // Formula: (Completed / Total) * 100
  double get completionRate {
    final dailyTasks = tasksForSelectedDate.where((t) => !t.isLocationTask && !t.isSafeExitTask).toList();
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

  // Theme & Settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('theme_mode') ?? false;
    _is24HourFormat = prefs.getBool('is24HourFormat') ?? true;
    _isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
    _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
    _isNotificationSound = prefs.getBool('isNotificationSound') ?? true;
    _isNotificationVibration = prefs.getBool('isNotificationVibration') ?? true;
    
    final List<String>? locationsData = prefs.getStringList('saved_locations_v1');
    if (locationsData != null) {
      _savedLocations = locationsData.map((e) => SavedLocation.fromJson(e)).toList();
    }
    
    notifyListeners();
  }

  Future<void> saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedData = _savedLocations
        .map((loc) => loc.toJson())
        .toList();
    await prefs.setStringList('saved_locations_v1', encodedData);
  }

  Future<void> addSavedLocation(SavedLocation location) async {
    _savedLocations.add(location);
    notifyListeners();
    await saveLocations();
  }

  Future<void> deleteSavedLocation(String id) async {
    _savedLocations.removeWhere((l) => l.id == id);
    notifyListeners();
    await saveLocations();
  }

  Future<void> updateSavedLocation(SavedLocation location) async {
    final index = _savedLocations.indexWhere((l) => l.id == location.id);
    if (index != -1) {
      _savedLocations[index] = location;
      notifyListeners();
      await saveLocations();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_mode', _isDarkMode);
  }

  Future<void> set24HourFormat(bool value) async {
    _is24HourFormat = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is24HourFormat', value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _isSoundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundEnabled', value);
  }

  Future<void> setNotificationEnabled(bool value) async {
    _isNotificationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', value);
  }

  Future<void> setNotificationSound(bool value) async {
    _isNotificationSound = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationSound', value);
  }

  Future<void> setNotificationVibration(bool value) async {
    _isNotificationVibration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationVibration', value);
  }

  // --- Statistics Logic ---

  /// Returns total completed tasks in the last 7 days grouped by index (0=today, 1=yesterday... 6=6 days ago)
  Map<int, int> get weeklyCompletionStats {
    final Map<int, int> stats = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final completedCount = _statisticalTasks.where((t) {
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
      final dayTasks = _statisticalTasks.where(
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

    final recentTasks = _statisticalTasks.where(
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
    final completedTasks = _statisticalTasks.where((t) => t.isCompleted);
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
    final completedTasks = _statisticalTasks.where((t) => t.isCompleted);
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
