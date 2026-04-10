import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

List<Position> _recentPositions = [];

Future<void> initializeBackgroundService() async {
  if (kIsWeb) return;

  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'Arka Plan Hizmeti',
    description: 'Arka planda konum ve hedefleri takip eder.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  LocationPermission permission = await Geolocator.checkPermission();
  bool canAutoStart = permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: canAutoStart,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Hedef Takip Çalışıyor',
      initialNotificationContent: 'Arka planda hedefler izleniyor',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: canAutoStart,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'location_channel_id',
    'Location Reminders',
    description: 'Notifications for location-based reminders',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
    service.on('stopService').listen((_) => service.stopSelf());
    service.on('update_notification').listen((event) {
      final content = (event != null && event['endTime'] != null)
          ? 'Konum koruması aktif (Saat ${event['endTime']}\'e kadar)'
          : 'Konum hedefleriniz uyanık durumda.';
      service.setForegroundNotificationInfo(
        title: 'Hedef Takip Çalışıyor',
        content: content,
      );
    });
    service.on('check_location').listen((_) async {
      await _performLocationCheck(
          service, flutterLocalNotificationsPlugin, _notifiedTasks);
    });
  }

  // 5 saniyede bir konum kontrolü
  Timer.periodic(const Duration(seconds: 5), (_) async {
    await _performLocationCheck(
        service, flutterLocalNotificationsPlugin, _notifiedTasks);
  });
}

// Servis genelinde bildirilenler — Timer kapsamı dışında tutmak için top-level
final Map<String, bool> _notifiedTasks = {};

Future<void> _performLocationCheck(
  ServiceInstance service,
  FlutterLocalNotificationsPlugin notifications,
  Map<String, bool> notifiedTasks,
) async {
  try {
    if (!(await Geolocator.isLocationServiceEnabled())) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    if (!(prefs.getBool('isNotificationEnabled') ?? true)) return;

    final bool playSound = prefs.getBool('isNotificationSound') ?? true;
    final bool enableVibration = prefs.getBool('isNotificationVibration') ?? true;

    final List<String>? encodedData = prefs.getStringList('tasks_data_v3');
    if (encodedData == null || encodedData.isEmpty) return;

    final now = DateTime.now();
    final allTasks = encodedData.map((e) => Task.fromJson(e)).toList();

    final locationTasks = allTasks.where((t) {
      if (t.isCompleted || t.latitude == null || t.longitude == null) return false;
      if (!t.isLocationTask && !t.isSafeExitTask) return false;
      if (t.date.year != now.year ||
          t.date.month != now.month ||
          t.date.day != now.day) {
        return false;
      }
      return true;
    }).toList();

    if (locationTasks.isEmpty) {
      service.stopSelf();
      return;
    }

    // Konum al
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null &&
          DateTime.now().difference(lastKnown.timestamp).inMinutes < 10) {
        position = lastKnown;
      } else {
        return;
      }
    }

    // GPS sıçramalarını düzelt — son 3 konumun ortalaması
    _recentPositions.add(position);
    if (_recentPositions.length > 3) _recentPositions.removeAt(0);

    double avgLat = 0.0, avgLng = 0.0;
    for (final p in _recentPositions) {
      avgLat += p.latitude;
      avgLng += p.longitude;
    }
    avgLat /= _recentPositions.length;
    avgLng /= _recentPositions.length;

    for (final task in locationTasks) {
      final distance = Geolocator.distanceBetween(
        avgLat, avgLng,
        task.latitude!, task.longitude!,
      );

      if (task.isSafeExitTask) {
        // Zaman aralığı kontrolü
        bool isTimeValid = true;
        if (task.startTime != null && task.endTime != null) {
          final nowMin = now.hour * 60 + now.minute;
          final startParts = task.startTime!.split(':');
          final endParts = task.endTime!.split(':');
          if (startParts.length == 2 && endParts.length == 2) {
            final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
            final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
            if (nowMin < startMin || nowMin > endMin) isTimeValid = false;
          }
        }

        if (distance > 50.0 && isTimeValid) {
          if (notifiedTasks[task.id] != true) {
            notifiedTasks[task.id] = true;
            _showNotification(
              notifications: notifications,
              id: task.id.hashCode.abs(),
              title: 'DİKKAT: ${task.locationName ?? "Konumdan"} ayrılıyorsun!',
              body: '${task.locationName ?? "Güvenli bölge"} konumundan ayrılıyorsun, [${task.title}] görevini unutma!',
              playSound: playSound,
              enableVibration: enableVibration,
            );
          }
        } else if (distance <= 50.0) {
          notifiedTasks[task.id] = false;
        }
      } else {
        // Standart konum görevi
        if (distance <= (task.radius ?? 1000.0)) {
          if (notifiedTasks[task.id] != true) {
            notifiedTasks[task.id] = true;
            _showNotification(
              notifications: notifications,
              id: task.id.hashCode.abs(),
              title: 'Hedefine Çok Yaklaştın: ${task.title}',
              body: task.notes?.isNotEmpty == true
                  ? task.notes!
                  : 'Şu an hedefe ${distance.toStringAsFixed(0)} metre mesafedesin!',
              playSound: playSound,
              enableVibration: enableVibration,
            );
          }
        } else {
          notifiedTasks[task.id] = false;
        }
      }
    }
  } catch (_) {
    // Sessizce devam et — kullanıcıya gösterilecek bir şey yok
  }
}

void _showNotification({
  required FlutterLocalNotificationsPlugin notifications,
  required int id,
  required String title,
  required String body,
  required bool playSound,
  required bool enableVibration,
}) {
  notifications.show(
    id,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'location_channel_id',
        'Location Reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: playSound,
        enableVibration: enableVibration,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(presentSound: playSound),
    ),
  );
}

Future<void> checkAndToggleService() async {
  if (kIsWeb) return;

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final List<String>? encodedData = prefs.getStringList('tasks_data_v3');

  final service = FlutterBackgroundService();
  final bool isRunning = await service.isRunning();

  if (encodedData == null || encodedData.isEmpty) {
    if (isRunning) service.invoke('stopService');
    return;
  }

  final now = DateTime.now();
  final allTasks = encodedData.map((e) => Task.fromJson(e)).toList();

  final hasLocationTasks = allTasks.any((t) {
    if (t.isCompleted || t.latitude == null || t.longitude == null) return false;
    if (t.date.year != now.year ||
        t.date.month != now.month ||
        t.date.day != now.day) {
      return false;
    }
    return true;
  });

  if (hasLocationTasks) {
    if (!isRunning) {
      try {
        await initializeBackgroundService();
        await service.startService();
      } catch (_) {}
    }
    service.invoke('update_notification', {'endTime': '7/24'});
  } else {
    if (isRunning) service.invoke('stopService');
  }
}
