import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onCompleted;

  const TaskItem({super.key, required this.task, this.onCompleted});

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<TaskProvider>().isDarkMode;
    final task = widget.task;

    final taskColor = task.colorValue != null
        ? Color(task.colorValue!)
        : CupertinoColors.systemBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.white.withValues(alpha: 0.4),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black26
                : Colors.blue.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                HapticFeedback.selectionClick();
              },
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 8,
                      color: taskColor.withValues(alpha: 0.8),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Checkbox
                            Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: task.isCompleted,
                                activeColor: taskColor,
                                shape: const CircleBorder(),
                                side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                onChanged: (bool? value) {
                                  HapticFeedback.mediumImpact();
                                  context.read<TaskProvider>().toggleTask(
                                    task.id,
                                  );
                                  if (value == true) {
                                    widget.onCompleted?.call();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category Initial Circle
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: taskColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                task.category.isNotEmpty
                                    ? task.category[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: taskColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                                  color: Colors.green,
                                ),
                              ),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'SF Pro Display',
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? (isDarkMode
                                                ? Colors.white30
                                                : Colors.grey[400])
                                          : (isDarkMode
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (task.isSafeExitTask && task.startTime != null && task.endTime != null && !task.isCompleted) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sadece ${task.startTime}-${task.endTime} arası koruma aktif',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  // Time Display (New Model uses 'time' string HH:mm)
                                  if (!task.isCompleted) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.time,
                                          size: 12,
                                          color: isDarkMode
                                              ? Colors.grey
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.time,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? Colors.grey
                                                : Colors.grey[600],
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
                                  size: 16,
                                  color: isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              ),

                            // Delete Button
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.trash,
                                size: 18,
                                color: Colors.red[300],
                              ),
                              onPressed: () {
                                HapticFeedback.heavyImpact();

                                // Enhanced Delete Confirmation Dialog
                                showCupertinoDialog(
                                  context: context,
                                  builder: (ctx) {
                                    if (task.isBulk) {
                                      // Bulk Task Options
                                      return CupertinoActionSheet(
                                        title: Text(
                                          '"${task.title}" Silinsin mi?',
                                        ),
                                        message: const Text(
                                          'Bu bir toplu hedefin parçasıdır.',
                                        ),
                                        actions: [
                                          CupertinoActionSheetAction(
                                            isDestructiveAction: true,
                                            onPressed: () {
                                              context
                                                  .read<TaskProvider>()
                                                  .deleteTask(task.id);
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text(
                                              'Sadece bu saati sil',
                                            ),
                                          ),
                                          CupertinoActionSheetAction(
                                            isDestructiveAction: true,
                                            onPressed: () {
                                              context
                                                  .read<TaskProvider>()
                                                  .deleteTaskSeries(
                                                    task.title,
                                                    task.date,
                                                  );
                                              Navigator.pop(ctx);
                                            },
                                            child: Text(
                                              'O güne ait tüm "${task.title}" kayıtlarını sil',
                                            ),
                                          ),
                                        ],
                                        cancelButton:
                                            CupertinoActionSheetAction(
                                              child: const Text('Vazgeç'),
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                            ),
                                      );
                                    } else {
                                      // Single Task Confirmation
                                      return CupertinoAlertDialog(
                                        title: const Text('Silinsin mi?'),
                                        content: const Text(
                                          'Bu görevi silmek istediğine emin misin?',
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: const Text('Vazgeç'),
                                            onPressed: () => Navigator.pop(ctx),
                                          ),
                                          CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            child: const Text('Sil'),
                                            onPressed: () {
                                              context
                                                  .read<TaskProvider>()
                                                  .deleteTask(task.id);
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expanded Notes
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.topCenter,
              child: _isExpanded && (task.notes?.isNotEmpty ?? false)
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.notes!,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
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
    );
  }
}
