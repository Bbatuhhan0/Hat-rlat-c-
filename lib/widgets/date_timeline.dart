import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class DateTimeline extends StatefulWidget {
  const DateTimeline({super.key});

  @override
  State<DateTimeline> createState() => _DateTimelineState();
}

class _DateTimelineState extends State<DateTimeline> {
  List<DateTime> _getWeekDates(DateTime baseDate) {
    // weekday 1 = Monday, 7 = Sunday
    final monday = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(List<DateTime> weekDates) {
    if (weekDates.isEmpty) return '';
    final first = weekDates.first;
    final last = weekDates.last;

    // Check if week spans two months (or years)
    if (first.month != last.month) {
      final firstMonth = DateFormat('MMMM', 'tr_TR').format(first);
      final lastMonth = DateFormat('MMMM', 'tr_TR').format(last);

      // If years are different, include year for both? Or just let standard format handle it.
      // User request: "Ocak - Şubat 2026" format.
      if (first.year != last.year) {
        return '${DateFormat('MMMM yyyy', 'tr_TR').format(first)} - ${DateFormat('MMMM yyyy', 'tr_TR').format(last)}';
      }

      return '$firstMonth - $lastMonth ${first.year}';
    } else {
      // Single month
      return DateFormat('MMMM yyyy', 'tr_TR').format(first);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isDarkMode = provider.isDarkMode;
    final weekDates = _getWeekDates(provider.selectedDate);
    final monthName = _getMonthName(weekDates);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          // Month Name Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: provider.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('tr', 'TR'),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData(
                          colorScheme: isDarkMode
                              ? const ColorScheme.dark(
                                  primary: CupertinoColors.systemBlue,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1C1C1E),
                                  onSurface: Colors.white,
                                )
                              : const ColorScheme.light(
                                  primary: CupertinoColors.systemBlue,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                          dialogTheme: DialogThemeData(
                            backgroundColor: isDarkMode
                                ? const Color(0xFF1C1C1E)
                                : Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    provider.setDate(picked);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _capitalize(monthName),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 24,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  provider.setDate(
                    provider.selectedDate.subtract(const Duration(days: 7)),
                  );
                },
                icon: Icon(
                  Icons.chevron_left,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 28,
                ),
                tooltip: 'Önceki Hafta',
              ),
              Expanded(
                child: SizedBox(
                  height: 105,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDates.map((date) {
                      final isSelected = _isSameDay(
                        date,
                        provider.selectedDate,
                      );
                      final isToday = _isSameDay(date, DateTime.now());

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            provider.setDate(date);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CupertinoColors.systemBlue
                                  : (isDarkMode
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: CupertinoColors.systemBlue,
                                      width: 1.5,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: CupertinoColors.systemBlue
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E', 'tr_TR').format(date),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : (isToday
                                              ? CupertinoColors.systemBlue
                                              : (isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  provider.setDate(
                    provider.selectedDate.add(const Duration(days: 7)),
                  );
                },
                icon: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 28,
                ),
                tooltip: 'Sonraki Hafta',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
