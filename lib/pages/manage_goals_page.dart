import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class ManageGoalsPage extends StatelessWidget {
  const ManageGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isDarkMode = provider.isDarkMode;
    final titles = provider.uniqueTaskTitles;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.black
          : CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: const Text('Hedefleri Yönet'),
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
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
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext ctx) => CupertinoActionSheet(
                            title: const Text('Silme Seçenekleri'),
                            message: Text("'$title' hedefi için işlem seçin"),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                    builder: (confirmCtx) => CupertinoAlertDialog(
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
                                          child: const Text('Evet, Sil'),
                                          onPressed: () {
                                            provider.deleteAllTasksWithTitle(
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
                );
              },
            ),
    );
  }
}
