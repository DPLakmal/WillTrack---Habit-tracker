import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'habit_symbol_icon.dart';

class HabitDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final String? initialCategory;
  final String? initialSymbol;
  final int? initialColor;
  final String? initialScheduleType;
  final String? initialScheduleDays;
  final int? initialWeeklyTargetDays;
  final DateTime? initialStartDate;
  final String? initialReminderTime;
  final bool? initialIsReminderEnabled;
  final String title;
  final String confirmLabel;

  const HabitDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialCategory,
    this.initialSymbol,
    this.initialColor,
    this.initialScheduleType,
    this.initialScheduleDays,
    this.initialWeeklyTargetDays,
    this.initialStartDate,
    this.initialReminderTime,
    this.initialIsReminderEnabled,
    required this.title,
    this.confirmLabel = 'Save',
  });

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class HabitDialogResult {
  final String name;
  final String? description;
  final String category;
  final String symbol;
  final int colorValue;
  final String scheduleType;
  final String scheduleDays;
  final int weeklyTargetDays;
  final DateTime startDate;
  final String? reminderTime;
  final bool isReminderEnabled;

  HabitDialogResult({
    required this.name,
    this.description,
    required this.category,
    required this.symbol,
    required this.colorValue,
    required this.scheduleType,
    required this.scheduleDays,
    required this.weeklyTargetDays,
    required this.startDate,
    this.reminderTime,
    required this.isReminderEnabled,
  });
}

class _HabitDialogState extends State<HabitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _categoryController;
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  late String _selectedSymbol;
  late int _selectedColor;

  // Scheduling
  late String _scheduleType; // 'daily', 'specific_days', 'weekly_target'
  late Set<int> _selectedDays; // 1=Mon, ..., 7=Sun
  late int _weeklyTarget;
  late DateTime _startDate;

  // Reminders
  late bool _isReminderEnabled;
  TimeOfDay? _reminderTimeOfDay;

  final List<String> _suggestedCategories = [
    'Fitness',
    'Learning',
    'Health',
    'Productivity',
    'General',
    'Mindfulness',
  ];

  final List<Map<String, dynamic>> _weekdays = [
    {'day': 1, 'label': 'Mon'},
    {'day': 2, 'label': 'Tue'},
    {'day': 3, 'label': 'Wed'},
    {'day': 4, 'label': 'Thu'},
    {'day': 5, 'label': 'Fri'},
    {'day': 6, 'label': 'Sat'},
    {'day': 7, 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descController =
        TextEditingController(text: widget.initialDescription ?? '');
    _selectedCategory = widget.initialCategory ?? 'Fitness';
    _categoryController = TextEditingController(text: _selectedCategory);
    _selectedSymbol = widget.initialSymbol ?? 'check';
    _selectedColor = widget.initialColor ?? HabitColors.palette[0];

    _scheduleType = widget.initialScheduleType ?? 'daily';
    _selectedDays = (widget.initialScheduleDays ?? '')
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
    if (_selectedDays.isEmpty && _scheduleType == 'specific_days') {
      _selectedDays = {1, 3, 5}; // Default Mon, Wed, Fri
    }
    _weeklyTarget = widget.initialWeeklyTargetDays ?? 3;
    _startDate = widget.initialStartDate ?? DateTime.now();

    _isReminderEnabled = widget.initialIsReminderEnabled ?? false;
    if (widget.initialReminderTime != null) {
      final parts = widget.initialReminderTime!.split(':');
      if (parts.length == 2) {
        _reminderTimeOfDay = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    } else {
      _reminderTimeOfDay = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim();
      final category = _categoryController.text.trim().isEmpty
          ? _selectedCategory
          : _categoryController.text.trim();

      String? timeStr;
      if (_reminderTimeOfDay != null && _isReminderEnabled) {
        final h = _reminderTimeOfDay!.hour.toString().padLeft(2, '0');
        final m = _reminderTimeOfDay!.minute.toString().padLeft(2, '0');
        timeStr = '$h:$m';
      }

      Navigator.of(context, rootNavigator: true).pop(
        HabitDialogResult(
          name: name,
          description: desc,
          category: category,
          symbol: _selectedSymbol,
          colorValue: _selectedColor,
          scheduleType: _scheduleType,
          scheduleDays: (_selectedDays.toList()..sort()).join(','),
          weeklyTargetDays: _weeklyTarget,
          startDate: _startDate,
          reminderTime: timeStr,
          isReminderEnabled: _isReminderEnabled,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Habit Name
                const Text('Habit Name',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  autofocus: widget.initialName == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'e.g. Daily Swimming, Read 30 mins',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a habit name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Description
                const Text('Description (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. 40 laps freestyle, hydrate properly',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Schedule Type
                const Text('Frequency / Schedule',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScheduleChip('daily', 'Every Day'),
                    const SizedBox(width: 6),
                    _buildScheduleChip('specific_days', 'Specific Days'),
                    const SizedBox(width: 6),
                    _buildScheduleChip('weekly_target', 'X / Week'),
                  ],
                ),
                const SizedBox(height: 10),

                // Specific Days Selection
                if (_scheduleType == 'specific_days') ...[
                  Wrap(
                    spacing: 6,
                    children: _weekdays.map((d) {
                      final dayNum = d['day'] as int;
                      final isSelected = _selectedDays.contains(dayNum);
                      return FilterChip(
                        label: Text(d['label'] as String),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedDays.add(dayNum);
                            } else {
                              if (_selectedDays.length > 1) {
                                _selectedDays.remove(dayNum);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Weekly Target Stepper
                if (_scheduleType == 'weekly_target') ...[
                  Row(
                    children: [
                      const Text('Target sessions per week: ',
                          style: TextStyle(fontSize: 13)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _weeklyTarget > 1
                            ? () => setState(() => _weeklyTarget--)
                            : null,
                      ),
                      Text('$_weeklyTarget',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _weeklyTarget < 7
                            ? () => setState(() => _weeklyTarget++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Start Date Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Start Date',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        DateFormat('MMM d, yyyy').format(_startDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),

                // Reminder Settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 18),
                        const SizedBox(width: 8),
                        const Text('Reminder Alert',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    Switch.adaptive(
                      value: _isReminderEnabled,
                      onChanged: (val) {
                        setState(() => _isReminderEnabled = val);
                      },
                    ),
                  ],
                ),
                if (_isReminderEnabled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reminder Time',
                          style: TextStyle(fontSize: 13)),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(
                          _reminderTimeOfDay != null
                              ? _reminderTimeOfDay!.format(context)
                              : '08:00 AM',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTimeOfDay ??
                                const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => _reminderTimeOfDay = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ],
                const Divider(),

                // Category selector
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _suggestedCategories.map((cat) {
                    final isSelected =
                        _selectedCategory.toLowerCase() == cat.toLowerCase();
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                            _categoryController.text = cat;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Symbol picker
                const Text('Completion Symbol',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HabitSymbols.options.map((opt) {
                    final isSelected = _selectedSymbol == opt.key;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedSymbol = opt.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(_selectedColor).withValues(alpha: 0.2)
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Color(_selectedColor)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          opt.icon,
                          size: 22,
                          color: isSelected
                              ? Color(_selectedColor)
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color palette
                const Text('Color Theme',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: HabitColors.palette.map((colorVal) {
                    final isSelected = _selectedColor == colorVal;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorVal),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Color(_selectedColor),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  Widget _buildScheduleChip(String type, String label) {
    final isSelected = _scheduleType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _scheduleType = type);
      },
    );
  }
}
