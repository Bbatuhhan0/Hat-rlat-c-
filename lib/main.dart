import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/home_page.dart';
import 'providers/task_provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  tz.initializeTimeZones();

  // Set system UI overlay style for cleaner look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  
  // Start background location tracking!
  await initializeBackgroundService();

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
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
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
            themeMode: taskProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.transparent,
              primaryColor: const Color(0xFF8E2DE2), // Electric purple to vivid blue gradient used elsewhere
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF8E2DE2),
                brightness: Brightness.light,
                surface: Colors.white.withValues(alpha: 0.7),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
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
                data: MediaQuery.of(
                  context,
                ).copyWith(alwaysUse24HourFormat: taskProvider.is24HourFormat),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: taskProvider.isDarkMode
                          ? const [Color(0xFF0F0C29), Color(0xFF302B63)]
                          : const [Color(0xFFF9F9FF), Color(0xFFE6E6FA)],
                    ),
                  ),
                  child: child!,
                ),
              );
            },
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
