import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';

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
                  color: (i == 0)
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.systemBlue.withValues(alpha: 0.5),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (maxCount < 5)
                        ? 5
                        : maxCount + 2, // dynamic background height
                    color: isDarkMode ? Colors.white10 : Colors.grey[200],
                  ),
                ),
              ],
            ),
          );
        }

        return AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Son 7 Gün',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
