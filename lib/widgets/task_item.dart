import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'dart:ui';

class TaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onCompleted;

  const TaskItem({super.key, required this.task, this.onCompleted});

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isExpanded = false;
  bool _isPressed = false;
  bool _showBurst = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<TaskProvider>().isDarkMode;
    final task = widget.task;

    final taskColor = task.colorValue != null
        ? Color(task.colorValue!)
        : CupertinoColors.systemBlue;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
        HapticFeedback.selectionClick();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        curve: Curves.bounceOut,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _showBurst ? taskColor.withValues(alpha: 0.6) : taskColor.withValues(alpha: 0.15),
                blurRadius: _showBurst ? 40 : 20,
                spreadRadius: _showBurst ? 10 : 2,
              ),
            ],
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(0.5), // Gradient border width
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23.5),
          color: isDarkMode 
             ? (task.isCompleted ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05))
             : (task.isCompleted ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.7)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Material(
              color: Colors.transparent,
              child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 8,
                        color: taskColor.withValues(alpha: task.isCompleted ? 0.3 : 0.8),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Custom Checkbox
                                  GestureDetector(
                                    onTap: () async {
                                      HapticFeedback.heavyImpact(); // Emphasized Haptic
                                      context.read<TaskProvider>().toggleTask(task.id);
                                      if (!task.isCompleted) {
                                        setState(() => _showBurst = true);
                                        Future.delayed(const Duration(milliseconds: 300), () {
                                          if (mounted) setState(() => _showBurst = false);
                                        });
                                        widget.onCompleted?.call();
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: task.isCompleted
                                            ? const LinearGradient(
                                                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        border: task.isCompleted
                                            ? null
                                            : Border.all(
                                                color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                      ),
                                      child: task.isCompleted
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Category Neon Ring
                                  Opacity(
                                    opacity: task.isCompleted ? 0.4 : 1.0,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: taskColor,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: taskColor.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ],
                                        color: taskColor.withValues(alpha: 0.1),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        task.category.isNotEmpty
                                            ? task.category[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: taskColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(
                                              color: taskColor,
                                              blurRadius: 10,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (task.isSafeExitTask)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.home_rounded,
                                        size: 22,
                                        color: task.isCompleted ? Colors.green.withValues(alpha: 0.4) : Colors.green,
                                      ),
                                    ),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedOpacity(
                                          duration: const Duration(milliseconds: 300),
                                          opacity: task.isCompleted ? 0.4 : 1.0,
                                          child: Text(
                                            task.title,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.5,
                                              fontFamily: 'SF Pro Display',
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (task.isSafeExitTask && task.startTime != null && task.endTime != null && !task.isCompleted) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Sadece ${task.startTime}-${task.endTime} arası koruma',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        // Time Display
                                        if (!task.isCompleted) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.time,
                                                size: 14,
                                                color: CupertinoColors.systemBlue.withValues(alpha: 0.8),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                task.time,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Note Icon
                                  if (task.notes != null && task.notes!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.notes,
                                        size: 18,
                                        color: task.isCompleted
                                            ? Colors.transparent
                                            : (isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                                      ),
                                    ),

                                  // Delete Button
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.trash,
                                      size: 20,
                                      color: task.isCompleted 
                                          ? Colors.red[300]!.withValues(alpha: 0.4) 
                                          : Colors.red[400],
                                    ),
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();

                                      showCupertinoDialog(
                                        context: context,
                                        builder: (ctx) {
                                          if (task.isBulk) {
                                            return CupertinoActionSheet(
                                              title: Text('"${task.title}" Silinsin mi?'),
                                              message: const Text('Bu bir toplu hedefin parçasıdır.'),
                                              actions: [
                                                CupertinoActionSheetAction(
                                                  isDestructiveAction: true,
                                                  onPressed: () {
                                                    context.read<TaskProvider>().deleteTask(task.id);
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Sadece bu saati sil'),
                                                ),
                                                CupertinoActionSheetAction(
                                                  isDestructiveAction: true,
                                                  onPressed: () {
                                                    context.read<TaskProvider>().deleteTaskSeries(task.title, task.date);
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: Text('O güne ait tüm "${task.title}" kayıtlarını sil'),
                                                ),
                                              ],
                                              cancelButton: CupertinoActionSheetAction(
                                                child: const Text('Vazgeç'),
                                                onPressed: () => Navigator.pop(ctx),
                                              ),
                                            );
                                          } else {
                                            return CupertinoAlertDialog(
                                              title: const Text('Silinsin mi?'),
                                              content: const Text('Bu görevi silmek istediğine emin misin?'),
                                              actions: [
                                                CupertinoDialogAction(
                                                  child: const Text('Vazgeç'),
                                                  onPressed: () => Navigator.pop(ctx),
                                                ),
                                                CupertinoDialogAction(
                                                  isDestructiveAction: true,
                                                  child: const Text('Sil'),
                                                  onPressed: () {
                                                    context.read<TaskProvider>().deleteTask(task.id);
                                                    Navigator.pop(ctx);
                                                  },
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              // Expanded Notes
                              AnimatedSize(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.elasticOut,
                                child: _isExpanded && (task.notes?.isNotEmpty ?? false)
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.only(top: 12, left: 40),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Divider(
                                              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              task.notes!,
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                                fontSize: 15,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
   );
  }
}
