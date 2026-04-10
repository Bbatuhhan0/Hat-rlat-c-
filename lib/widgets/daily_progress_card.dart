import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Sadece ilgili alanları izle — gereksiz rebuild yok
    final ratio = context.select<TaskProvider, double>((p) => p.dailyCompletionRatio);
    final isDarkMode = context.select<TaskProvider, bool>((p) => p.isDarkMode);
    final hasTasks = context.select<TaskProvider, bool>((p) => p.tasksForSelectedDate.isNotEmpty);

    if (!hasTasks) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: ratio),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animatedRatio, _) {
                  final pct = (animatedRatio * 100).toInt();
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Arka iz
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF8E2DE2).withValues(alpha: 0.15),
                        ),
                      ),
                      // İlerleme
                      CircularProgressIndicator(
                        value: animatedRatio,
                        strokeWidth: 10,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF8E2DE2),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                      // Yüzde
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '%$pct',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: isDarkMode ? Colors.white : Colors.black87,
                                letterSpacing: -1.0,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Opacity(
                              opacity: 0.55,
                              child: Text(
                                'TAMAMLANDI',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ratio == 1.0 ? 'Mükemmel! 🎉' : 'Harika gidiyorsun! 💪',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ratio == 1.0
                        ? 'Bugünlük tüm planlarını eksiksiz bitirdin!'
                        : 'Bugünün hedeflerine adım adım yaklaşıyorsun.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
