import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../pages/map_picker_screen.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isBulkMode = false;
  String _selectedRepetition = 'monthly'; // 'monthly', 'yearly'

  DateTime _selectedDate = DateTime.now();
  final List<TimeOfDay> _bulkTimes = [TimeOfDay.now()];
  TimeOfDay _singleTime = TimeOfDay.now();
  Color _selectedColor = Colors.blue;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationName;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  Future<void> _selectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
        _selectedLocationName = result['address'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<TaskProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final inputColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mode Segmented Control
          CupertinoSlidingSegmentedControl<bool>(
            groupValue: _isBulkMode,
            children: const {
              false: Text('Tekli Hedef'),
              true: Text('Toplu Hedef'),
            },
            onValueChanged: (val) {
              setState(() {
                _isBulkMode = val ?? false;
              });
            },
          ),
          const SizedBox(height: 20),

          // Title
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              final tasks = context.read<TaskProvider>().tasks;
              final suggestions = tasks.map((t) => t.title).toSet().toList();
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return suggestions.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              _titleController.text = selection;
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
                  if (controller.text != _titleController.text) {
                    // Sync logic
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (text) => _titleController.text = text,
                    decoration: InputDecoration(
                      hintText: 'Ne yapacaksın?',
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: textColor),
                  );
                },
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Not ekle (İsteğe bağlı)',
              filled: true,
              fillColor: inputColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: textColor),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Bulk Options: Repetition Type
          if (_isBulkMode) ...[
            const Text(
              'Tekrarlama Sıklığı',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _selectedRepetition == 'daily'
                  ? 'monthly'
                  : _selectedRepetition,
              children: const {
                'monthly': Text('Aylık'),
                'yearly': Text('Yıllık'),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _selectedRepetition = val);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Date Selection
          // Date Selection (Only for Single Task)
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isBulkMode
                        ? 'Başlangıç: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate)}'
                        : DateFormat(
                            'dd MMMM yyyy',
                            'tr_TR',
                          ).format(_selectedDate),
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time Selection
          if (_isBulkMode) ...[
            const Text(
              'Saatler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                ..._bulkTimes.map(
                  (time) => Chip(
                    label: Text(time.format(context)),
                    onDeleted: () {
                      setState(() {
                        _bulkTimes.remove(time);
                      });
                    },
                  ),
                ),
                ActionChip(
                  label: const Icon(Icons.add, size: 16),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _bulkTimes.add(time);
                      });
                    }
                  },
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _singleTime,
                );
                if (time != null) {
                  setState(() => _singleTime = time);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: inputColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _singleTime.format(context),
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Location Selection
          GestureDetector(
            onTap: () => _selectLocation(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedLocationName ?? 'Konum Ekle (Opsiyonel)',
                      style: TextStyle(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedLatitude != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedLatitude = null;
                          _selectedLongitude = null;
                          _selectedLocationName = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Color Selection
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final color = _colors[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: textColor, width: 2)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Add Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _selectedColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (_titleController.text.isEmpty) return;

              final List<String> times = _isBulkMode
                  ? _bulkTimes.map((t) => '${t.hour}:${t.minute}').toList()
                  : ['${_singleTime.hour}:${_singleTime.minute}'];

              if (times.isEmpty) return;

              // Debug check
              // print('Adding task: bulk=$_isBulkMode, rep=$_selectedRepetition');

              context.read<TaskProvider>().addTask(
                title: _titleController.text,
                date: _selectedDate,
                times: times,
                notes: _notesController.text,
                colorValue: _selectedColor.toARGB32(),
                category: 'Genel',
                isBulk: _isBulkMode,
                repetitionType: _isBulkMode ? _selectedRepetition : 'none',
                latitude: _selectedLatitude,
                longitude: _selectedLongitude,
                radius: 1000.0,
              );

              Navigator.pop(context);
            },
            child: const Text(
              'Hedef Ekle',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
