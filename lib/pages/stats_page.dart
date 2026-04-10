import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/glass_card.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E2DE2).withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A00E0).withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<TaskProvider>(
                  builder: (context, provider, child) {
                    final isDarkMode = provider.isDarkMode;
                    return Text(
                      'Genel Başarı',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Consumer<TaskProvider>(
                  builder: (context, provider, _) {
                    final isDarkMode = provider.isDarkMode;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGreen.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: GlassCard(
                        isDarkMode: isDarkMode,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BU HAFTANIN YILDIZI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemGreen,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'En verimli gün: ${provider.mostProductiveDay}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                const WeeklyChart(),
                const SizedBox(height: 30),
                Consumer<TaskProvider>(
                  builder: (context, provider, _) {
                    return GlassCard(
                      isDarkMode: provider.isDarkMode,
                      padding: const EdgeInsets.all(16),
                      child: _build30DayEfficiencyChart(
                        provider.isDarkMode,
                        provider,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Consumer<TaskProvider>(
                  builder: (context, provider, _) {
                    return GlassCard(
                      isDarkMode: provider.isDarkMode,
                      padding: const EdgeInsets.all(16),
                      child: _buildMonthlyPieChart(provider.isDarkMode, provider),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Consumer<TaskProvider>(
                  builder: (context, provider, child) {
                    final stats = provider.topCategories;
                    final isDarkMode = provider.isDarkMode;

                    if (stats.isEmpty) {
                      return Center(
                        child: Text(
                          'Henüz yeterli veri yok.',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    final sortedEntries = stats.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'En Çok Yapılanlar',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...sortedEntries.map((entry) {
                          return GlassCard(
                            isDarkMode: isDarkMode,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF8E2DE2).withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
                                    ]
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    entry.key.isNotEmpty
                                        ? entry.key[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _capitalize(entry.key),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${entry.value} kez',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
       ),
      ],
     ),
    );
  }

  Widget _build30DayEfficiencyChart(bool isDarkMode, TaskProvider provider) {
    final stats = provider.monthlyCompletionRates;
    final now = DateTime.now();

    // 30 günlükleri en eskiden bugüne sırala (29 days ago → today)
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '30 Günlük Aktivite',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            // Legend
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Boş',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E2DE2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tam',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Ay isimleri satırı
        Row(
          children: [
            for (int week = 0; week < 5; week++) ...[
              if (week < 4) ...[  
                Expanded(
                  child: Text(
                    _weekLabel(days[week * 6]),
                    style: TextStyle(
                      fontSize: 9,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[  
                Expanded(
                  child: Text(
                    _weekLabel(days[29]),
                    style: TextStyle(
                      fontSize: 9,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Activity Grid
        AspectRatio(
          aspectRatio: 5.0, // 30 hücre = 6 satır x 5 sütun için iyi oran
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,   // 10 sütun x 3 satır = 30 gün
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              // index 0 = 29 days ago, index 29 = today
              final dayIndex = 29 - index; // stats[0]=today, stats[29]=oldest
              final rate = stats[dayIndex] ?? 0.0;
              final isToday = index == 29;
              
              // Renk: veri yoksa çok açık, veri varsa yoğunluğa göre mor
              Color cellColor;
              if (rate <= 0.0) {
                cellColor = isDarkMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08);
              } else if (rate < 0.25) {
                cellColor = const Color(0xFF8E2DE2).withValues(alpha: 0.25);
              } else if (rate < 0.5) {
                cellColor = const Color(0xFF8E2DE2).withValues(alpha: 0.50);
              } else if (rate < 0.75) {
                cellColor = const Color(0xFF8E2DE2).withValues(alpha: 0.75);
              } else {
                cellColor = const Color(0xFF8E2DE2);
              }

              return Tooltip(
                message: '${DateFormat('d MMM', 'tr_TR').format(days[index])}: ${(rate * 100).toStringAsFixed(0)}%',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(3),
                    border: isToday
                        ? Border.all(color: const Color(0xFF8E2DE2), width: 1.5)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Tamamlanma oranı ortalaması
        Builder(builder: (context) {
          final nonZero = stats.values.where((v) => v > 0);
          if (nonZero.isEmpty) return const SizedBox.shrink();
          final avg = nonZero.reduce((a, b) => a + b) / nonZero.length;
          return Text(
            '30 gün ortalaması: %${(avg * 100).toStringAsFixed(0)} tamamlanma',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
          );
        }),
      ],
    );
  }

  String _weekLabel(DateTime date) {
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[date.month - 1];
  }

  Widget _buildMonthlyPieChart(bool isDarkMode, TaskProvider provider) {
    final stats = provider.monthlyCategoryStats;
    if (stats.isEmpty) return const SizedBox.shrink();

    int i = 0;
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Dağılımı (Son 30 Gün)',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: stats.entries.map((e) {
                final color = colors[i++ % colors.length];
                return PieChartSectionData(
                  color: color,
                  value: e.value * 100, // percentage
                  title: '${(e.value * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: stats.keys.toList().asMap().entries.map((e) {
            final index = e.key;
            final name = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: colors[index % colors.length],
                ),
                const SizedBox(width: 4),
                Text(
                  _capitalize(name),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
