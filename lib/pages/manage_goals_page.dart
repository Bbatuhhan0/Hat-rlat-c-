import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class ManageGoalsPage extends StatelessWidget {
  const ManageGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // context.select ile sadece ilgili alanlar izleniyor — gereksiz rebuild yok
    final isDarkMode = context.select<TaskProvider, bool>((p) => p.isDarkMode);
    final titles = context.select<TaskProvider, List<String>>((p) => p.uniqueTaskTitles);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F0C29)
          : const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: const Text('Hedefleri Yönet'),
        backgroundColor: isDarkMode
            ? const Color(0xFF0F0C29)
            : const Color(0xFFF9F9FF),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: titles.length,
              itemExtent: 108, // Sabit yükseklik → ListView daha hızlı render eder
              itemBuilder: (context, index) {
                final title = titles[index];
                return RepaintBoundary(
                  child: _GoalCard(
                    key: ValueKey(title),
                    title: title,
                    isDarkMode: isDarkMode,
                  ),
                );
              },
            ),
    );
  }
}

// Her kart kendi widget'ı olduğu için bağımsız rebuild edilir
class _GoalCard extends StatelessWidget {
  final String title;
  final bool isDarkMode;

  const _GoalCard({super.key, required this.title, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    // Sadece bu karta ait task sayısını seç
    final taskCount = context.select<TaskProvider, int>(
      (p) => p.tasks.where((t) => t.title == title).length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9),
            isDarkMode
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.7),
          ],
        ),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      // BackdropFilter kaldırıldı — her item için blur büyük perf maliyeti
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.5,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          'Toplam $taskCount kayıt',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
                message: Text("'$title' hedefi için işlem seçin"),
                actions: <CupertinoActionSheetAction>[
                  CupertinoActionSheetAction(
                    child: const Text('Belirli Bir Tarih Aralığını Sil'),
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
                        // ignore: use_build_context_synchronously
                        context.read<TaskProvider>().deleteTasksWithTitleInRange(
                              title,
                              dateRange.start,
                              dateRange.end,
                            );
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Seçili aralıktaki hedefler silindi.'),
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
                              onPressed: () => Navigator.pop(confirmCtx),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Evet, Sil'),
                              onPressed: () {
                                context
                                    .read<TaskProvider>()
                                    .deleteAllTasksWithTitle(title);
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
  }
}
