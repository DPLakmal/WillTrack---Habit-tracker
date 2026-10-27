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
  final double? initialTargetValue;
  final String? initialUnit;
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
    this.initialTargetValue,
    this.initialUnit,
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
  final double? targetValue;
  final String? unit;
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
    this.targetValue,
    this.unit,
    this.reminderTime,
    required this.isReminderEnabled,
  });
}

class _HabitDialogState extends State<HabitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _categoryController;
  late final TextEditingController _targetValueController;
  late final TextEditingController _unitController;
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  late String _selectedSymbol;
  late int _selectedColor;

  // Numerical Goals
  bool _hasNumericalGoal = false;

  // Scheduling
  late String _scheduleType; // 'daily', 'specific_days', 'weekly_target'
  late Set<int> _selectedDays; // 1=Mon, ..., 7=Sun
  late int _weeklyTarget;
  late DateTime _startDate;

  // Reminders
  late bool _isReminderEnabled;
  TimeOfDay? _reminderTimeOfDay;

  bool _isAdvancedExpanded = false;

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

    _hasNumericalGoal = widget.initialTargetValue != null && widget.initialTargetValue! > 0;
    _targetValueController = TextEditingController(
      text: widget.initialTargetValue != null
          ? (widget.initialTargetValue! % 1 == 0
              ? widget.initialTargetValue!.toInt().toString()
              : widget.initialTargetValue!.toString())
          : '',
    );
    _unitController = TextEditingController(text: widget.initialUnit ?? 'mins');

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

    // Auto-expand advanced options if editing existing habit with custom schedules/reminders/goals
    if (widget.initialScheduleType != null &&
        (widget.initialScheduleType != 'daily' ||
            widget.initialIsReminderEnabled == true ||
            _hasNumericalGoal ||
            (widget.initialDescription != null &&
                widget.initialDescription!.isNotEmpty))) {
      _isAdvancedExpanded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
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

      final double? targetVal = _hasNumericalGoal
          ? double.tryParse(_targetValueController.text.trim())
          : null;
      final String? unitStr = _hasNumericalGoal && _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : null;

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
          targetValue: targetVal,
          unit: unitStr,
          reminderTime: timeStr,
          isReminderEnabled: _isReminderEnabled,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color(_selectedColor);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.4,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Habit Name Input
                  const Text('Habit Name',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    autofocus: widget.initialName == null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'e.g. Daily Swimming, Read 30 mins',
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
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

                  // Category Selector Chips
                  const Text('Category',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestedCategories.map((cat) {
                        final isSelected = _selectedCategory.toLowerCase() ==
                            cat.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: primaryColor.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black87),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.transparent,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _categoryController.text = cat;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Icon & Color Theme Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Selector
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Icon',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: HabitSymbols.options.map((opt) {
                                  final isSelected = _selectedSymbol == opt.key;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => setState(
                                          () => _selectedSymbol = opt.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor.withValues(alpha: 0.2)
                                              : (isDark
                                                  ? Colors.grey[850]
                                                  : Colors.grey[100]),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          opt.icon,
                                          size: 20,
                                          color: isSelected
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600]),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Color Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Color',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: HabitColors.palette.take(4).map((cVal) {
                              final isSelected = _selectedColor == cVal;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = cVal),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(cVal),
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white, width: 2.5)
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
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Expandable Advanced Options (Schedule, Reminder, Description)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(
                        () => _isAdvancedExpanded = !_isAdvancedExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAdvancedExpanded
                                    ? Icons.tune
                                    : Icons.tune_outlined,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isAdvancedExpanded
                                    ? 'Hide Schedule & Reminder'
                                    : 'More Options (Schedule, Reminders)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _isAdvancedExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Advanced Section Body
                  if (_isAdvancedExpanded) ...[
                    const Divider(height: 20),

                    // Description
                    const Text('Description (Optional)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. 40 laps freestyle, hydrate properly',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Frequency / Schedule
                    const Text('Frequency / Schedule',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildScheduleChip('daily', 'Every Day'),
                          const SizedBox(width: 6),
                          _buildScheduleChip('specific_days', 'Specific Days'),
                          const SizedBox(width: 6),
                          _buildScheduleChip('weekly_target', 'X / Week'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Specific Days Selection
                    if (_scheduleType == 'specific_days') ...[
                      Wrap(
                        spacing: 4,
                        children: _weekdays.map((d) {
                          final dayNum = d['day'] as int;
                          final isSelected = _selectedDays.contains(dayNum);
                          return FilterChip(
                            label: Text(d['label'] as String,
                                style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      const SizedBox(height: 8),
                    ],

                    // Weekly Target Stepper
                    if (_scheduleType == 'weekly_target') ...[
                      Row(
                        children: [
                          const Text('Target days per week: ',
                              style: TextStyle(fontSize: 13)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 20),
                            onPressed: _weeklyTarget > 1
                                ? () => setState(() => _weeklyTarget--)
                                : null,
                          ),
                          Text('$_weeklyTarget',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                size: 20),
                            onPressed: _weeklyTarget < 7
                                ? () => setState(() => _weeklyTarget++)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Start Date Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Start Date',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            DateFormat('MMM d, yyyy').format(_startDate),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
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

                    // Numerical Goal Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 16),
                            const SizedBox(width: 6),
                            const Text('Measurable Target Goal',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                        Switch.adaptive(
                          value: _hasNumericalGoal,
                          activeTrackColor: primaryColor,
                          onChanged: (val) {
                            setState(() => _hasNumericalGoal = val);
                          },
                        ),
                      ],
                    ),
                    if (_hasNumericalGoal) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _targetValueController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                hintText: 'e.g. 30',
                                labelText: 'Target Amount',
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _unitController,
                              decoration: InputDecoration(
                                hintText: 'mins, ml, pages',
                                labelText: 'Unit',
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Reminder Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined,
                                size: 16),
                            const SizedBox(width: 6),
                            const Text('Daily Reminder',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isReminderEnabled,
                          activeTrackColor: primaryColor,
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
                            icon: const Icon(Icons.access_time, size: 15),
                            label: Text(
                              _reminderTimeOfDay != null
                                  ? _reminderTimeOfDay!.format(context)
                                  : '08:00 AM',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                  ],

                  const SizedBox(height: 20),

                  // Actions Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.confirmLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleChip(String type, String label) {
    final isSelected = _scheduleType == type;
    final primaryColor = Color(_selectedColor);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: primaryColor.withValues(alpha: 0.2),
      onSelected: (val) {
        if (val) setState(() => _scheduleType = type);
      },
    );
  }
}
