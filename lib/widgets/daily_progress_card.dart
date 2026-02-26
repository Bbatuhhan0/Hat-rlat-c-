import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final ratio = provider.dailyCompletionRatio;
        final percentage = provider.completionRate.toInt();
        final isDarkMode = provider.isDarkMode;

        if (provider.tasksForSelectedDate.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    Center(
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 6,
                        backgroundColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          CupertinoColors.systemGreen,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Center(
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMotivationMessage(percentage),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bugün %$percentage tamamlandı',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMotivationMessage(int percentage) {
    if (percentage == 100) return "Mükemmel Gün! 🎉";
    if (percentage >= 75) return "Harika gidiyorsun! 💪";
    if (percentage >= 50) return "Yarıladın bile! 🚀";
    if (percentage >= 25) return "İyi başlangıç! 👍";
    return "Harekete geç! 🔥";
  }
}
