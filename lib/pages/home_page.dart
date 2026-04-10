import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/date_timeline.dart';
import '../widgets/daily_progress_card.dart';
import 'stats_page.dart';
import 'manage_goals_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<TaskProvider, bool>((p) => p.isDarkMode);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(isDarkMode),
      backgroundColor: Colors.transparent,
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: _isSheetOpen ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        builder: (context, val, child) {
          if (val == 0.0) return child!;
          return Transform.scale(
            scale: 1.0 - (val * 0.05),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: val * 0.35),
                BlendMode.darken,
              ),
              child: child,
            ),
          );
        },
        child: CupertinoTabScaffold(
          backgroundColor: Colors.transparent,
          tabBar: CupertinoTabBar(
            backgroundColor: Colors.transparent,
            activeColor: const Color(0xFF8E2DE2),
            inactiveColor: isDarkMode ? Colors.white54 : Colors.black54,
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.list_bullet),
                activeIcon: Icon(
                  CupertinoIcons.list_bullet,
                  color: Color(0xFF8E2DE2),
                  shadows: [Shadow(color: Color(0xFF8E2DE2), blurRadius: 12)],
                ),
                label: 'Görevler',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chart_bar_fill),
                activeIcon: Icon(
                  CupertinoIcons.chart_bar_fill,
                  color: Color(0xFF8E2DE2),
                  shadows: [Shadow(color: Color(0xFF8E2DE2), blurRadius: 12)],
                ),
                label: 'İstatistikler',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            if (index == 0) {
              return CupertinoPageScaffold(
                backgroundColor: Colors.transparent,
                child: Stack(
                  children: [
                    _buildTaskView(isDarkMode),
                    Positioned(
                      bottom: 90,
                      right: 20,
                      child: FloatingActionButton(
                        heroTag: 'addTask',
                        onPressed: () async {
                          setState(() => _isSheetOpen = true);
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            builder: (context) => const AddTaskSheet(),
                          );
                          if (mounted) setState(() => _isSheetOpen = false);
                        },
                        child: const Icon(CupertinoIcons.add),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const CupertinoPageScaffold(
              backgroundColor: Colors.transparent,
              child: StatsPage(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskView(bool isDarkMode) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // AppBar — BackdropFilter kaldırıldı
        SliverAppBar(
          backgroundColor: isDarkMode
              ? const Color(0xFF0F0C29).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          expandedHeight: 60,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.grey, size: 30),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDarkMode
                    ? const [Color(0xFFE0E0E0), Color(0xFFFFFFFF)]
                    : const [Color(0xFF333333), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Zaman Takip',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon_fill,
                color: isDarkMode ? Colors.yellow : Colors.black,
              ),
              onPressed: () => context.read<TaskProvider>().toggleTheme(),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Column(
            children: const [
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: DailyProgressCard(),
              ),
              SizedBox(height: 20),
              DateTimeline(),
              SizedBox(height: 12),
            ],
          ),
        ),

        // Görev Listesi
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: Selector<TaskProvider, List>(
            selector: (_, p) => p.tasksForSelectedDate,
            builder: (context, tasks, _) {
              if (tasks.isEmpty) {
                return const SliverToBoxAdapter(child: _EmptyStateCard());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => TaskItem(
                    key: ValueKey(tasks[index].id),
                    task: tasks[index],
                  ),
                  childCount: tasks.length,
                ),
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
            accountName: const Text('Batuhan Işık'),
            accountEmail: const Text('YBS'),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.list_bullet),
            title: Text(
              'Hedefleri Yönet',
              style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const ManageGoalsPage(),
                  ),
                );
              });
            },
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.settings),
            title: Text(
              'Ayarlar',
              style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const SettingsPage()),
                );
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Tüm Verileri Temizle',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Tüm Veriler Silinecek!'),
                  content: const Text(
                    'Kayıtlı tüm görevler ve istatistikler kalıcı olarak silinecek. Bu işlem geri alınamaz.',
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

// Görev yok durumu — ayrı const widget: rebuild yok
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<TaskProvider, bool>((p) => p.isDarkMode);
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 8, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.85),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.checkmark_seal,
              size: 56,
              color: const Color(0xFF8E2DE2).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
              ).createShader(bounds),
              child: const Text(
                'Her Şey Planlandı! ✨',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bugünlük her şey yolunda.\nYeni bir hedef eklemeye ne dersin?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
