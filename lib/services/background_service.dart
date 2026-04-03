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
  if (kIsWeb) {
    print("[SERVICE] Web platformunda arka plan servisi desteklenmediğinden başlatılmadı.");
    return;
  }

  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'Arka Plan Hizmeti', // title
    description: 'Arka planda konum ve hedefleri takip eder.',
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Gerekli izinleri kontrol etmeden servisi otomatik başlatmak Android 14'te çökmeye neden olur
  LocationPermission permission = await Geolocator.checkPermission();
  bool canAutoStart = permission == LocationPermission.always || permission == LocationPermission.whileInUse;

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

  // Create channel for active notifications
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

  // Bring service to foreground
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // A memory state to keep track of notified tasks
  final Map<String, bool> notifiedTasks = {};

  // Keep foreground service alive by updating notification
  if (service is AndroidServiceInstance) {
    service.on('update_notification').listen((event) {
      String content = "Konum hedefleriniz uyanık durumda.";
      if (event != null && event['endTime'] != null) {
        content = "Konum koruması aktif (Saat ${event['endTime']}'e kadar)";
      }
      service.setForegroundNotificationInfo(
        title: "SERVİS ŞU AN ÇALIŞIYOR",
        content: content,
      );
    });
  }

    if (service is AndroidServiceInstance) {
      service.on('check_location').listen((event) async {
        await _performLocationCheck(service, flutterLocalNotificationsPlugin, notifiedTasks);
      });
    }

  // Timer for location checking
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    await _performLocationCheck(service, flutterLocalNotificationsPlugin, notifiedTasks);
  });
}

Future<void> _performLocationCheck(
    ServiceInstance service,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    Map<String, bool> notifiedTasks,
) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService() == false) {
        // Degraded to background
      }
    }

    try {
      print("[SERVICE] _performLocationCheck tetiklendi.");

      if (!(await Geolocator.isLocationServiceEnabled())) {
        print("[SERVICE] Konum servisi kapalı!");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); 

      final bool isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
      if (!isNotificationEnabled) return;

      final bool playSound = prefs.getBool('isNotificationSound') ?? true;
      final bool enableVibration = prefs.getBool('isNotificationVibration') ?? true;

      final List<String>? encodedData = prefs.getStringList('tasks_data_v3');
      if (encodedData == null || encodedData.isEmpty) return;

      final now = DateTime.now();
      final List<Task> allTasks = encodedData.map((e) => Task.fromJson(e)).toList();

      final locationTasks = allTasks.where((t) {
        if (t.isCompleted || t.latitude == null || t.longitude == null) {
          return false;
        }
        if (!t.isLocationTask && !t.isSafeExitTask) {
          return false; // Maksimum performans: sadece konum bazlıları süzecek
        }
        if (t.date.year != now.year || t.date.month != now.month || t.date.day != now.day) {
          return false;
        }
        return true;
      }).toList();

      if (locationTasks.isEmpty) {
        print("[SERVICE] Aktif konum görevi yok, servis kendi kendini durduruyor...");
        service.stopSelf();
        return;
      }

      print("[SERVICE] ${locationTasks.length} adet konum görevi taraması başlatılıyor...");

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            timeLimit: Duration(seconds: 8), 
          ),
        );
        print("[SERVICE] Konum başarıyla alındı: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("[SERVICE] Konum alınamadı, hata: $e");
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && DateTime.now().difference(lastKnown.timestamp).inMinutes < 10) {
          position = lastKnown;
        } else {
          return;
        }
      }

      // Fix GPS Jumps (Son 3 konum ortalaması)
      _recentPositions.add(position);
      if (_recentPositions.length > 3) _recentPositions.removeAt(0);

      double avgLat = 0.0;
      double avgLng = 0.0;
      for (var p in _recentPositions) {
        avgLat += p.latitude;
        avgLng += p.longitude;
      }
      avgLat /= _recentPositions.length;
      avgLng /= _recentPositions.length;

      for (var task in locationTasks) {
        final distance = Geolocator.distanceBetween(
          avgLat,
          avgLng,
          task.latitude!,
          task.longitude!,
        );

        print("[SERVICE] Görev: ${task.title} - Mevcut Mesafe: ${distance.toStringAsFixed(2)} metre (Gereken: ${task.radius ?? 100})");

        if (task.isSafeExitTask) {
          bool isTimeValid = true;
          if (task.startTime != null && task.endTime != null) {
            final nowMin = now.hour * 60 + now.minute;
            final startParts = task.startTime!.split(':');
            final endParts = task.endTime!.split(':');
            if (startParts.length == 2 && endParts.length == 2) {
              final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
              final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
              if (nowMin < startMin || nowMin > endMin) {
                isTimeValid = false;
              }
            }
          }

          if (distance > 100.0 && isTimeValid) {
            print("[SERVICE] UYARI TETIKLENDI! Mesafe: ${distance.toStringAsFixed(2)}m");
            if (notifiedTasks[task.id] != true) {
              notifiedTasks[task.id] = true;

              flutterLocalNotificationsPlugin.show(
                task.id.hashCode.abs(),
                'DİKKAT: ${task.locationName ?? "Konumdan"} ayrılıyorsun!',
                '${task.locationName ?? "Güvenli bölge"} konumundan ayrılıyorsun, [${task.title}] görevini unutma!',
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
                  iOS: DarwinNotificationDetails(
                    presentSound: playSound,
                  ),
                ),
              );
            }
          } else if (distance <= 100.0) {
            notifiedTasks[task.id] = false;
          }
        } else {
          // Standard Location Task logic
          if (distance <= (task.radius ?? 1000.0)) {
            if (notifiedTasks[task.id] != true) {
              notifiedTasks[task.id] = true;

              flutterLocalNotificationsPlugin.show(
                task.id.hashCode.abs(),
                'Hedefine Çok Yaklaştın: ${task.title}',
                task.notes?.isNotEmpty == true
                    ? task.notes!
                    : 'Şu an hedefe ${distance.toStringAsFixed(0)} metre mesafedesin!',
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
                  iOS: DarwinNotificationDetails(
                    presentSound: playSound,
                  ),
                ),
              );
            }
          } else {
            notifiedTasks[task.id] = false;
          }
        }
      }
    } catch (e) {
      print("[SERVICE] HATA OLUSTU: $e");
    }
}

Future<void> checkAndToggleService() async {
  if (kIsWeb) {
    print("[SERVICE] Web platformunda arka plan servisi başlatılamıyor.");
    return;
  }
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final List<String>? encodedData = prefs.getStringList('tasks_data_v3');
  
  final service = FlutterBackgroundService();
  bool isRunning = await service.isRunning();

  if (encodedData == null || encodedData.isEmpty) {
    if (isRunning) service.invoke('stopService');
    return;
  }

  final now = DateTime.now();
  final allTasks = encodedData.map((e) => Task.fromJson(e)).toList();

  final locationTasks = allTasks.where((t) {
    if (t.isCompleted || t.latitude == null || t.longitude == null) {
      return false;
    }
    if (t.date.year != now.year || t.date.month != now.month || t.date.day != now.day) {
      return false;
    }
    return true;
  }).toList();

  bool shouldRun = locationTasks.isNotEmpty;

  if (shouldRun) {
    if (!isRunning) {
      try {
        await service.startService();
        print("[SERVICE] Başlatıldı!");
      } catch (e) {
        print("[SERVICE] Başlatılamadı: $e");
      }
    }
    service.invoke('update_notification', {'endTime': '7/24'});
  } else {
    if (isRunning) {
      service.invoke('stopService');
      print("[SERVICE] Durduruldu!");
    }
  }
}

