import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/date_timeline.dart';
import '../widgets/daily_progress_card.dart';
import 'stats_page.dart';
import 'manage_goals_page.dart';
import 'settings_page.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    bool allGranted = true;

    if (!await Permission.location.request().isGranted) allGranted = false;
    if (!await Permission.locationAlways.request().isGranted) allGranted = false;
    if (!await Permission.notification.request().isGranted) allGranted = false;
    if (!await Permission.ignoreBatteryOptimizations.request().isGranted) allGranted = false;

    if (!allGranted && mounted) {
      _showPermissionWarning();
    }
  }

  void _showPermissionWarning() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eksik İzinler!'),
        content: const Text(
          'Arka planda konum ve ayrılma hatırlatıcılarının düzgün çalışması için "Her Zaman Konum", "Bildirim" ve "Pil Optimizasyonunu Yoksay" izinlerini vermeniz gerekmektedir.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Anladım'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Ayarlara Git'),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _triggerCelebration() {
    setState(() => _showCelebration = true);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch dark mode
    final isDarkMode = context.watch<TaskProvider>().isDarkMode;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(isDarkMode),
      body: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          activeColor: CupertinoColors.systemBlue,
          inactiveColor: CupertinoColors.systemGrey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet),
              label: 'Görevler',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar_fill),
              label: 'İstatistikler',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          if (index == 0) {
            return CupertinoPageScaffold(
              backgroundColor: isDarkMode
                  ? Colors.black
                  : CupertinoColors.systemGroupedBackground,
              child: Stack(
                children: [
                  // Main List
                  _buildTaskView(isDarkMode),

                  // FAB
                  Positioned(
                    bottom: 90,
                    right: 20,
                    child: FloatingActionButton(
                      heroTag: 'addTask',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: isDarkMode
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => const AddTaskSheet(),
                        );
                      },
                      child: const Icon(CupertinoIcons.add),
                    ),
                  ),

                  // Celebration
                  if (_showCelebration)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Lottie.network(
                          'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json',
                          fit: BoxFit.cover,
                          repeat: false,
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return CupertinoPageScaffold(
              backgroundColor: isDarkMode
                  ? Colors.black
                  : CupertinoColors.systemGroupedBackground,
              child: const StatsPage(),
            );
          }
        },
      ),
    );
  }

  Widget _buildTaskView(bool isDarkMode) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 50), // Safe Area equiv
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.grey,
                        size: 30,
                      ),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    IconButton(
                      icon: Icon(
                        isDarkMode
                            ? CupertinoIcons.sun_max
                            : CupertinoIcons.moon_fill,
                        color: isDarkMode ? Colors.yellow : Colors.black,
                      ),
                      onPressed: () =>
                          context.read<TaskProvider>().toggleTheme(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const DateTimeline(),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: DailyProgressCard(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Task List
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: Consumer<TaskProvider>(
            builder: (context, provider, _) {
              final tasks = provider.tasksForSelectedDate;

              if (tasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.tray,
                            size: 50,
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bugün için planlanan rutin yok',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = tasks[index];
                  return TaskItem(
                    key: ValueKey(task.id), // Stable String Key
                    task: task,
                    onCompleted: _triggerCelebration,
                  );
                }, childCount: tasks.length),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(bool isDarkMode) {
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : CupertinoColors.systemBlue,
            ),
            accountName: const Text("Batuhan Işık"),
            accountEmail: const Text("YBS"),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.list_bullet),
            title: Text(
              'Hedefleri Yönet',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const ManageGoalsPage(),
                ),
              );
            },
          ),
          ListTile(
            title: Text(
              'Ayarlar',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Tüm Verileri Temizle',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Tüm Veriler Silinecek!'),
                  content: const Text(
                    'Kayıtlı tüm görevler ve istatistikler kalıcı olarak silinecek. Bu işlem geri alınamaz. Onaylıyor musunuz?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Vazgeç'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Evet, Temizle'),
                      onPressed: () {
                        context.read<TaskProvider>().clearAllTasks();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
