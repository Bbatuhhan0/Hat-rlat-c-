import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/saved_location.dart';
import 'map_picker_screen.dart';
import 'dart:math';

class ManageLocationsPage extends StatelessWidget {
  const ManageLocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isDarkMode = provider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konumlarım'),
      ),
      body: provider.savedLocations.isEmpty
          ? Center(
              child: Text(
                'Henüz kayıtlı bir konumunuz yok.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : ListView.builder(
              itemCount: provider.savedLocations.length,
              itemBuilder: (context, index) {
                final loc = provider.savedLocations[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: Text(loc.name),
                  subtitle: Text('${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      provider.deleteSavedLocation(loc.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MapPickerScreen(),
            ),
          );

          if (result != null && result is Map<String, dynamic>) {
            final lat = result['latitude'] as double?;
            final lng = result['longitude'] as double?;
            
            if (lat != null && lng != null && context.mounted) {
              final nameController = TextEditingController();
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Konum Adı'),
                  content: Column(
                    children: [
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: nameController,
                        placeholder: 'Örn: İş, Ev, Okul',
                      ),
                    ],
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('İptal'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoDialogAction(
                      child: const Text('Kaydet'),
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final newLoc = SavedLocation(
                            id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
                            name: nameController.text,
                            latitude: lat,
                            longitude: lng,
                          );
                          provider.addSavedLocation(newLoc);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
