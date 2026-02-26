import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../widgets/weekly_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                      'İstatistikler',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: CupertinoColors.systemGreen.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
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
                    return _build30DayEfficiencyChart(
                      provider.isDarkMode,
                      provider,
                    );
                  },
                ),
                const SizedBox(height: 30),
                Consumer<TaskProvider>(
                  builder: (context, provider, _) {
                    return _buildMonthlyPieChart(provider.isDarkMode, provider);
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...sortedEntries.map((entry) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2C2C2E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemBlue
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    entry.key.isNotEmpty
                                        ? entry.key[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: CupertinoColors.systemBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _capitalize(entry.key),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${entry.value} kez',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
                  color: CupertinoColors.systemBlue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.2),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
