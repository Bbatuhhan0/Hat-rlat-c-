import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import 'glass_card.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final stats = provider.weeklyCompletionStats;
        final isDarkMode = provider.isDarkMode;
        final now = DateTime.now();

        // Prepare data for the chart
        // stats keys: 0=Today, 1=Yesterday... 6=6 days ago
        // We want to show left-to-right from 6 days ago to Today.
        final List<BarChartGroupData> barGroups = [];
        double maxCount = 0;

        for (int i = 6; i >= 0; i--) {
          final count = stats[i]?.toDouble() ?? 0.0;
          if (count > maxCount) maxCount = count;

          barGroups.add(
            BarChartGroupData(
              x: 6 - i, // 0 to 6
              barRods: [
                BarChartRodData(
                  toY: count,
                  gradient: (i == 0)
                      ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                      : LinearGradient(colors: [const Color(0xFF8E2DE2).withValues(alpha: 0.4), const Color(0xFF4A00E0).withValues(alpha: 0.4)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: false,
                  ),
                ),
              ],
            ),
          );
        }

        return AspectRatio(
          aspectRatio: 1.5,
          child: GlassCard(
            isDarkMode: isDarkMode,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Son 7 Gün',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      maxY: (maxCount < 5) ? 5 : maxCount + 2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          // tooltipBgColor: isDarkMode ? Colors.grey[800]! : Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              rod.toY.toInt().toString(),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              // value 0..6 corresponding to (Today-6)..(Today)
                              final int daysAgo = 6 - value.toInt();
                              final date = now.subtract(
                                Duration(days: daysAgo),
                              );
                              final dayName = DateFormat.E(
                                'tr_TR',
                              ).format(date); // e.g. Pzt
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  dayName,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
