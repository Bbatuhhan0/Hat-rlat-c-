import 'dart:convert';

class SubTask {
  final String title;
  final bool isDone;

  SubTask({required this.title, this.isDone = false});

  Map<String, dynamic> toMap() => {'title': title, 'isDone': isDone};

  factory SubTask.fromMap(Map<String, dynamic> map) => 
      SubTask(title: map['title'], isDone: map['isDone'] == true);

  SubTask copyWith({String? title, bool? isDone}) =>
      SubTask(title: title ?? this.title, isDone: isDone ?? this.isDone);
}

class Task {
  final String id;
  final String title;
  final String? notes;
  final DateTime date;
  final String time; // "HH:mm"
  final bool isCompleted;
  final int? colorValue;
  final bool isBulk; // New field
  final bool isLocationTask;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final bool isSafeExitTask; // New field for Safe Exit tasks
  final String? locationName;
  final String? startTime;
  final String? endTime;
  final List<SubTask> subTasks;

  // Compatibility fields
  final String category;
  final int streakCount;
  final int currentCount;
  final int targetCount;

  Task({
    required this.id,
    required this.title,
    this.notes,
    required this.date,
    required this.time,
    this.isCompleted = false,
    this.colorValue,
    this.isBulk = false,
    this.isLocationTask = false,
    this.category = 'Genel',
    this.streakCount = 0,
    this.currentCount = 0,
    this.targetCount = 1,
    this.latitude,
    this.longitude,
    this.radius = 1000.0,
    this.isSafeExitTask = false,
    this.locationName,
    this.startTime,
    this.endTime,
    this.subTasks = const [],
  });

  // Derived property for UI
  DateTime get reminderTime {
    try {
      final parts = time.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return date;
    }
  }

  // Compatibility getters
  String? get uuid => id;
  String? get lastCompletedDate => null;

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? date,
    String? time,
    bool? isCompleted,
    int? colorValue,
    bool? isBulk,
    bool? isLocationTask,
    String? category,
    int? streakCount,
    int? currentCount,
    int? targetCount,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isSafeExitTask,
    String? locationName,
    String? startTime,
    String? endTime,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      colorValue: colorValue ?? this.colorValue,
      isBulk: isBulk ?? this.isBulk,
      isLocationTask: isLocationTask ?? this.isLocationTask,
      category: category ?? this.category,
      streakCount: streakCount ?? this.streakCount,
      currentCount: currentCount ?? this.currentCount,
      targetCount: targetCount ?? this.targetCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isSafeExitTask: isSafeExitTask ?? this.isSafeExitTask,
      locationName: locationName ?? this.locationName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'date': date.toIso8601String(),
      'time': time,
      'isCompleted': isCompleted,
      'colorValue': colorValue,
      'isBulk': isBulk,
      'isLocationTask': isLocationTask,
      'category': category,
      'streakCount': streakCount,
      'currentCount': currentCount,
      'targetCount': targetCount,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isSafeExitTask': isSafeExitTask,
      'locationName': locationName,
      'startTime': startTime,
      'endTime': endTime,
      'subTasks': subTasks.map((st) => st.toMap()).toList(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      notes: map['notes'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      isCompleted: map['isCompleted'] == true,
      colorValue: map['colorValue'],
      isBulk: map['isBulk'] ?? false,
      isLocationTask: map['isLocationTask'] ?? false,
      category: map['category'] ?? 'Genel',
      streakCount: map['streakCount'] ?? 0,
      currentCount: map['currentCount'] ?? 0,
      targetCount: map['targetCount'] ?? 1,
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      radius: map['radius'] != null
          ? (map['radius'] as num).toDouble()
          : 1000.0,
      isSafeExitTask: map['isSafeExitTask'] ?? false,
      locationName: map['locationName'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      subTasks: map['subTasks'] != null 
          ? (map['subTasks'] as List).map((e) => SubTask.fromMap(e)).toList() 
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
