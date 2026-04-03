import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    // Convert map 0..29 (days ago) to spots.
    // X axis: 0 is 30 days ago, 29 is today.
    // stats[0] is Today (so X=29), stats[29] is 30 days ago (so X=0).

    List<FlSpot> spots = [];
    for (int i = 0; i < 30; i++) {
      // i is days ago.
      // We want left-to-right graph. 0 on X axis = 30 days ago.
      double x = (29 - i).toDouble();
      double y = stats[i] ?? 0.0;
      spots.add(FlSpot(x, y));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '30 Günlük Verimlilik',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 29,
              minY: 0,
              maxY: 1.2, // bit of space on top
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF4A00E0),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFF8E2DE2),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF8E2DE2).withValues(alpha: 0.5),
                        const Color(0xFF4A00E0).withValues(alpha: 0.0),
                      ],
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
