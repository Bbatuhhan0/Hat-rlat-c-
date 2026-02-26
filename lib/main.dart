import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/home_page.dart';
import 'providers/task_provider.dart';

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
              scaffoldBackgroundColor: const Color(0xFFF2F2F7),
              primaryColor: CupertinoColors.systemBlue,
              colorScheme: ColorScheme.fromSeed(
                seedColor: CupertinoColors.systemBlue,
                brightness: Brightness.light,
                surface: Colors.white,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF2F2F7),
                elevation: 0,
                scrolledUnderElevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  fontFamily: '.SF Pro Display',
                ),
                iconTheme: IconThemeData(color: Colors.black),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: CupertinoColors.systemBlue,
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
              scaffoldBackgroundColor: const Color(0xFF1C1C1E),
              primaryColor: CupertinoColors.systemBlue,
              colorScheme: ColorScheme.fromSeed(
                seedColor: CupertinoColors.systemBlue,
                brightness: Brightness.dark,
                surface: const Color(0xFF2C2C2E),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1C1C1E),
                elevation: 0,
                scrolledUnderElevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  fontFamily: '.SF Pro Display',
                ),
                iconTheme: IconThemeData(color: Colors.white),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: CupertinoColors.systemBlue,
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
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
