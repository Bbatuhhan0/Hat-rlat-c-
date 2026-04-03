import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final ratio = provider.dailyCompletionRatio;
        final isDarkMode = provider.isDarkMode;

        if (provider.tasksForSelectedDate.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: SizedBox(
            width: 220,
            height: 220,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: ratio),
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutCubic,
              builder: (context, animatedRatio, _) {
                final animatedPercentage = (animatedRatio * 100).toInt();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Soft glow shadow behind the ring
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Background track
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 16,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    // Gradient progress
                    ShaderMask(
                      shaderCallback: (rect) {
                        return SweepGradient(
                          startAngle: -1.57, // Start from top (-pi/2)
                          endAngle: 4.71,   // End at top (3pi/2)
                          colors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                          stops: const [0.0, 0.5, 1.0],
                          transform: GradientRotation(animatedRatio * 3.14), // dynamic rotation effect
                        ).createShader(rect);
                      },
                      child: CircularProgressIndicator(
                        value: animatedRatio,
                        strokeWidth: 16,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Inner content
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$animatedPercentage%',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              letterSpacing: -2,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tamamlandı',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              letterSpacing: 0.5,
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
        );
      },
    );
  }
}
