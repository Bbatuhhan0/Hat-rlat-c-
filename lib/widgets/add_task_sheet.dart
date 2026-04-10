import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/saved_location.dart';
import '../models/task_model.dart';
import '../pages/map_picker_screen.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _subTaskController = TextEditingController();
  final List<SubTask> _subTasks = [];
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  void _addSubTask() {
    if (_subTaskController.text.trim().isNotEmpty) {
      setState(() {
        _subTasks.add(SubTask(title: _subTaskController.text.trim()));
        _subTaskController.clear();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_titleController.text.trim().isEmpty) return false;
    if (_taskMode == 'location' && (_selectedLatitude == null || _selectedLongitude == null)) return false;
    if (_taskMode == 'safe_exit' && _selectedSavedLocation == null) return false;
    if (_taskMode == 'bulk' && _bulkTimes.isEmpty) return false;
    return true;
  }

  String _taskMode = 'single'; // 'single', 'bulk', 'location'
  String _selectedRepetition = 'monthly'; // 'monthly', 'yearly'

  DateTime _selectedDate = DateTime.now();
  final List<TimeOfDay> _bulkTimes = [TimeOfDay.now()];
  TimeOfDay _singleTime = TimeOfDay.now();
  TimeOfDay _safeExitStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _safeExitEndTime = const TimeOfDay(hour: 9, minute: 0);
  String _safeExitScheduleMode = 'single'; // 'single', 'multiple', 'routine'
  final List<DateTime> _safeExitMultipleDates = [DateTime.now()];
  Color _selectedColor = Colors.blue;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationName;
  double _selectedRadius = 1000.0;
  
  SavedLocation? _selectedSavedLocation;

  final Set<int> _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};
  final Map<int, String> _weekdays = {
    1: 'Pzt',
    2: 'Sal',
    3: 'Çar',
    4: 'Per',
    5: 'Cum',
    6: 'Cmt',
    7: 'Paz',
  };

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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      // BackdropFilter kaldırıldı — sheet açılırken tüm ekranı blur etmeye gerek yok
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF1C1C2E).withValues(alpha: 0.97)
              : Colors.white.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
        ),
        child: SingleChildScrollView(
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
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _taskMode,
                  children: const {
                    'single': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Tekli Hedef', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    'bulk': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Toplu Hedef', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    'location': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Konumlu Hedef', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    'safe_exit': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Ayrılma Hatırlatıcısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  },
                  onValueChanged: (val) {
                    setState(() {
                      if (val != null) _taskMode = val;
                    });
                  },
                ),
              ),
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

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: InputDecoration(
                      hintText: 'Alt Görev Ekle',
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    onSubmitted: (_) => _addSubTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addSubTask,
                  icon: const Icon(CupertinoIcons.add_circled_solid, size: 32, color: Color(0xFF8E2DE2)),
                ),
              ],
            ),
            if (_subTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._subTasks.asMap().entries.map((entry) {
                final index = entry.key;
                final subTask = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(subTask.title, style: TextStyle(color: textColor)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _subTasks.removeAt(index)),
                        child: const Icon(CupertinoIcons.trash, size: 18, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),

            // Bulk Options: Repetition Type
            if (_taskMode == 'bulk') ...[
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

            if (_taskMode == 'safe_exit') ...[
              const Text(
                'Zamanlama Modu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _safeExitScheduleMode,
                children: const {
                  'single': Text('Tek Gün'),
                  'multiple': Text('Çok Gün'),
                  'routine': Text('Rutin'),
                },
                onValueChanged: (val) {
                  if (val != null) setState(() => _safeExitScheduleMode = val);
                },
              ),
              const SizedBox(height: 16),
            ],

            if (_taskMode == 'bulk' || (_taskMode == 'safe_exit' && _safeExitScheduleMode == 'routine')) ...[
              const Text(
                'Hangi Günler?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _weekdays.entries.map((entry) {
                  final isSelected = _selectedWeekdays.contains(entry.key);
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWeekdays.add(entry.key);
                        } else {
                          if (_selectedWeekdays.length > 1) { // Protect from empty selection
                            _selectedWeekdays.remove(entry.key);
                          }
                        }
                      });
                    },
                    selectedColor: _selectedColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Date Selection
            if (_taskMode != 'safe_exit' || (_taskMode == 'safe_exit' && _safeExitScheduleMode == 'single')) ...[
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
                      _taskMode == 'bulk'
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
            ] else if (_taskMode == 'safe_exit' && _safeExitScheduleMode == 'multiple') ...[
              const Text(
                'Hangi Tarihler?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ..._safeExitMultipleDates.map((date) => Chip(
                    label: Text(DateFormat('dd MMM yy', 'tr_TR').format(date)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                         _safeExitMultipleDates.remove(date);
                      });
                    },
                  )),
                  ActionChip(
                    label: const Icon(Icons.add, size: 16),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null && !_safeExitMultipleDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day)) {
                        setState(() => _safeExitMultipleDates.add(date));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Time Selection
            if (_taskMode == 'safe_exit') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
                      isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.6),
                    ],
                  ),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.07),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.clock, size: 16, color: Color(0xFF8E2DE2)),
                        const SizedBox(width: 6),
                        Text(
                          'Koruma Saatleri',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.3,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Belirtilen saatler arasında konumdan ayrılınca bildirim gönderilir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // START TIME
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BAŞLANGIÇ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF8E2DE2).withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  await showCupertinoModalPopup(
                                    context: context,
                                    builder: (ctx) => Container(
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      child: CupertinoTimerPicker(
                                        mode: CupertinoTimerPickerMode.hm,
                                        initialTimerDuration: Duration(
                                          hours: _safeExitStartTime.hour,
                                          minutes: _safeExitStartTime.minute,
                                        ),
                                        onTimerDurationChanged: (duration) {
                                          setState(() {
                                            _safeExitStartTime = TimeOfDay(
                                              hour: duration.inHours,
                                              minute: duration.inMinutes % 60,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8E2DE2).withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.time, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _safeExitStartTime.format(context),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            CupertinoIcons.arrow_right,
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BİTİŞ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF4A00E0).withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  await showCupertinoModalPopup(
                                    context: context,
                                    builder: (ctx) => Container(
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      child: CupertinoTimerPicker(
                                        mode: CupertinoTimerPickerMode.hm,
                                        initialTimerDuration: Duration(
                                          hours: _safeExitEndTime.hour,
                                          minutes: _safeExitEndTime.minute,
                                        ),
                                        onTimerDurationChanged: (duration) {
                                          setState(() {
                                            _safeExitEndTime = TimeOfDay(
                                              hour: duration.inHours,
                                              minute: duration.inMinutes % 60,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF4A00E0),
                                        const Color(0xFF8E2DE2).withValues(alpha: 0.7),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4A00E0).withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.time, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _safeExitEndTime.format(context),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_taskMode == 'bulk') ...[
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
            ] else if (_taskMode == 'single') ...[
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
            if (_taskMode == 'safe_exit') ...[
              if (context.read<TaskProvider>().savedLocations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lütfen Ayarlar > Konumlarım bölümünden kayıtlı bir konum ekleyin.',
                    style: TextStyle(color: isDarkMode ? Colors.red[300] : Colors.red[700]),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SavedLocation>(
                      value: _selectedSavedLocation,
                      hint: Text(
                        'Kayıtlı Konum Seç (Zorunlu)',
                        style: TextStyle(color: textColor),
                      ),
                      dropdownColor: backgroundColor,
                      icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                      isExpanded: true,
                      items: context.read<TaskProvider>().savedLocations.map((loc) {
                        return DropdownMenuItem<SavedLocation>(
                          value: loc,
                          child: Text(loc.name, style: TextStyle(color: textColor)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSavedLocation = val;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ] else if (_taskMode == 'location') ...[
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
                          _selectedLocationName ?? 'Konum Seç (Zorunlu)',
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
              const Text(
                'Mesafe Çapı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<double>(
                groupValue: _selectedRadius,
                children: <double, Widget>{
                  500.0: const Text('500m'),
                  1000.0: const Text('1KM'),
                  2000.0: const Text('2KM'),
                  5000.0: const Text('5KM'),
                },
                onValueChanged: (val) {
                  setState(() {
                    if (val != null) _selectedRadius = val;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

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
            _PulseButtonWrapper(
              animate: _isFormValid && !_isSaving,
              color: _selectedColor,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSaving
                    ? Container(
                        key: const ValueKey('saving'),
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CircularProgressIndicator(color: _selectedColor),
                      )
                    : ElevatedButton(
                        key: const ValueKey('btn'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _selectedColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (!_isFormValid) return;
                          
                          if (_subTaskController.text.trim().isNotEmpty) {
                            _addSubTask();
                          }
                          
                          setState(() => _isSaving = true);

                          final List<String> times;
                          if (_taskMode == 'bulk') {
                            times = _bulkTimes.map((t) => '${t.hour}:${t.minute}').toList();
                          } else if (_taskMode == 'location' || _taskMode == 'safe_exit') {
                            times = ['00:00'];
                          } else {
                            times = ['${_singleTime.hour}:${_singleTime.minute}'];
                          }

                          Future.delayed(const Duration(milliseconds: 1500), () async {
                            if (!mounted) return;
                            try {
                              await context.read<TaskProvider>().addTask(
                                title: _titleController.text,
                                date: _selectedDate,
                                times: times,
                                notes: _notesController.text,
                                colorValue: _selectedColor.toARGB32(),
                                category: _taskMode == 'safe_exit' 
                                    ? 'Ayrılma Hatırlatıcısı' 
                                    : (_taskMode == 'location' ? 'Konum' : 'Genel'),
                                isBulk: _taskMode == 'bulk' || (_taskMode == 'safe_exit' && _safeExitScheduleMode != 'single'),
                                repetitionType: _taskMode == 'bulk'
                                    ? _selectedRepetition
                                    : (_taskMode == 'safe_exit' && _safeExitScheduleMode == 'routine' ? 'daily' : 'none'),
                                selectedWeekdays: (_taskMode == 'bulk' || (_taskMode == 'safe_exit' && _safeExitScheduleMode == 'routine')) 
                                    ? _selectedWeekdays.toList() 
                                    : null,
                                specificDates: (_taskMode == 'safe_exit' && _safeExitScheduleMode == 'multiple')
                                    ? _safeExitMultipleDates
                                    : null,
                                latitude: _taskMode == 'safe_exit' ? _selectedSavedLocation!.latitude : _selectedLatitude,
                                longitude: _taskMode == 'safe_exit' ? _selectedSavedLocation!.longitude : _selectedLongitude,
                                locationName: _taskMode == 'safe_exit' ? _selectedSavedLocation!.name : _selectedLocationName,
                                startTime: _taskMode == 'safe_exit' 
                                    ? '${_safeExitStartTime.hour.toString().padLeft(2, '0')}:${_safeExitStartTime.minute.toString().padLeft(2, '0')}' 
                                    : null,
                                endTime: _taskMode == 'safe_exit' 
                                    ? '${_safeExitEndTime.hour.toString().padLeft(2, '0')}:${_safeExitEndTime.minute.toString().padLeft(2, '0')}' 
                                    : null,
                                radius: _taskMode == 'safe_exit' ? 50.0 : _selectedRadius,
                                isLocationTask: _taskMode == 'location' || _taskMode == 'safe_exit',
                                isSafeExitTask: _taskMode == 'safe_exit',
                                subTasks: _subTasks,
                              );
                              if (!mounted) return;
                              Navigator.pop(context);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bildirim kurulamadı, lütfen izinlerinizi kontrol edin.'),
                                  backgroundColor: Colors.redAccent,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                              setState(() => _isSaving = false);
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                               Text(
                                'Görevi Kaydet',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                               ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
       ),
      ),
    );
  }
}

class _PulseButtonWrapper extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Color color;

  const _PulseButtonWrapper({required this.child, required this.animate, required this.color});

  @override
  State<_PulseButtonWrapper> createState() => _PulseButtonWrapperState();
}

class _PulseButtonWrapperState extends State<_PulseButtonWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseButtonWrapper old) {
    super.didUpdateWidget(old);
    if (widget.animate && !old.animate) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && old.animate) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: widget.animate ? 1.0 + (_controller.value * 0.03) : 1.0,
        child: Container(
          decoration: widget.animate ? BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * _controller.value),
                blurRadius: 15 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ) : null,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
