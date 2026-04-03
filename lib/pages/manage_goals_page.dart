import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'dart:ui';

class ManageGoalsPage extends StatelessWidget {
  const ManageGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isDarkMode = provider.isDarkMode;
    final titles = provider.uniqueTaskTitles;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // the gradient from main.dart will show through!
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Hedefleri Yönet',
        ), // removed const for shader if needed, but not doing shader on subtitle pages
        backgroundColor: isDarkMode
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: titles.isEmpty
          ? Center(
              child: Text(
                'Henüz eklenmiş bir hedef yok.',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: titles.length,
              itemBuilder: (context, index) {
                final title = titles[index];
                final taskCount = provider.tasks
                    .where((t) => t.title == title)
                    .length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.9),
                        isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.7),
                      ],
                    ),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Toplam $taskCount kayıt',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.trash,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext ctx) => CupertinoActionSheet(
                                title: const Text('Silme Seçenekleri'),
                                message: Text(
                                  "'$title' hedefi için işlem seçin",
                                ),
                                actions: <CupertinoActionSheetAction>[
                                  CupertinoActionSheetAction(
                                    child: const Text(
                                      'Belirli Bir Tarih Aralığını Sil',
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      final DateTimeRange? dateRange =
                                          await showDateRangePicker(
                                            context: context,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                            helpText: 'Tarih Aralığı Seç',
                                            confirmText: 'Sil',
                                            saveText: 'Sil',
                                          );

                                      if (dateRange != null) {
                                        provider.deleteTasksWithTitleInRange(
                                          title,
                                          dateRange.start,
                                          dateRange.end,
                                        );
                                        // ignore: use_build_context_synchronously
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Seçili aralıktaki hedefler silindi.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  CupertinoActionSheetAction(
                                    isDestructiveAction: true,
                                    child: const Text('Tüm Zamanlardan Sil'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (confirmCtx) =>
                                            CupertinoAlertDialog(
                                              title: const Text('Hedefi Sil'),
                                              content: Text(
                                                "'$title' isimli tüm hedefler sistemden tamamen silinecek. Onaylıyor musunuz?",
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  child: const Text('İptal'),
                                                  onPressed: () =>
                                                      Navigator.pop(confirmCtx),
                                                ),
                                                CupertinoDialogAction(
                                                  isDestructiveAction: true,
                                                  child: const Text(
                                                    'Evet, Sil',
                                                  ),
                                                  onPressed: () {
                                                    provider
                                                        .deleteAllTasksWithTitle(
                                                          title,
                                                        );
                                                    Navigator.pop(confirmCtx);
                                                  },
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('İptal'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
