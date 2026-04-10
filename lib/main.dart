import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/splash_screen.dart';
import 'providers/task_provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  tz.initializeTimeZones();

  final notificationService = NotificationService();
  await notificationService.init();

  // Konum görevi varsa servisi başlat — pil optimizasyonu
  final prefs = await SharedPreferences.getInstance();
  final encodedTasks = prefs.getStringList('tasks_data_v3') ?? [];
  final hasActiveLocationTask = encodedTasks.any((raw) {
    return raw.contains('"isLocationTask":true') ||
        raw.contains('"isSafeExitTask":true');
  });

  if (hasActiveLocationTask) {
    await initializeBackgroundService();
  }

  runApp(const MyApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TaskProvider())],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    // Sadece isDarkMode ve is24HourFormat değişince rebuild olur
    final isDarkMode = context.select<TaskProvider, bool>((p) => p.isDarkMode);
    final is24Hour = context.select<TaskProvider, bool>((p) => p.is24HourFormat);

    return MaterialApp(
      title: 'Zaman Takip',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: const Color(0xFF8E2DE2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E2DE2),
          brightness: Brightness.light,
          surface: Colors.white.withValues(alpha: 0.7),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            fontFamily: '.SF Pro Display',
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8E2DE2),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: const Color(0xFF8E2DE2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E2DE2),
          brightness: Brightness.dark,
          surface: Colors.white.withValues(alpha: 0.1),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            fontFamily: '.SF Pro Display',
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8E2DE2),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineSmall: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: is24Hour),
          child: Stack(
            children: [
              // Gradient arka plan
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? const [Color(0xFF0F0C29), Color(0xFF302B63)]
                        : const [Color(0xFFF9F9FF), Color(0xFFE6E6FA)],
                  ),
                ),
              ),
              // Blob dekoratörleri — önbelleğe alındı, tema değişiminde bile sadece bir kez çizilir
              RepaintBoundary(
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? const Color(0xFF8E2DE2).withValues(alpha: 0.25)
                                : const Color(0xFFCBB8FF)
                                    .withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 100,
                      left: -100,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? const Color(0xFFFF0080).withValues(alpha: 0.25)
                                : const Color(0xFFB8D8FF)
                                    .withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              child!,
            ],
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
