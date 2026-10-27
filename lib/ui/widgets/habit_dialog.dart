import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import 'habit_symbol_icon.dart';

class HabitDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final String? initialCategory;
  final String? initialSymbol;
  final int? initialColor;
  final String? initialHabitType;
  final String? initialRoutine;
  final int? initialStackedHabitId;
  final String? initialStackTrigger;
  final int? initialGoalId;
  final String? initialScheduleType;
  final String? initialScheduleDays;
  final int? initialWeeklyTargetDays;
  final DateTime? initialStartDate;
  final double? initialTargetValue;
  final String? initialUnit;
  final String? initialReminderTime;
  final bool? initialIsReminderEnabled;
  final List<Habit>? availableHabits;
  final List<Goal>? availableGoals;
  final String title;
  final String confirmLabel;

  const HabitDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialCategory,
    this.initialSymbol,
    this.initialColor,
    this.initialHabitType,
    this.initialRoutine,
    this.initialStackedHabitId,
    this.initialStackTrigger,
    this.initialGoalId,
    this.initialScheduleType,
    this.initialScheduleDays,
    this.initialWeeklyTargetDays,
    this.initialStartDate,
    this.initialTargetValue,
    this.initialUnit,
    this.initialReminderTime,
    this.initialIsReminderEnabled,
    this.availableHabits,
    this.availableGoals,
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
  final String habitType;
  final String routine;
  final int? stackedHabitId;
  final String? stackTrigger;
  final int? goalId;
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
    required this.habitType,
    required this.routine,
    this.stackedHabitId,
    this.stackTrigger,
    this.goalId,
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
  late final TextEditingController _stackTriggerController;
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  late String _selectedSymbol;
  late int _selectedColor;

  // Habit Type & Routine
  late String _habitType; // 'boolean', 'quantity', 'duration'
  late String _routine; // 'anytime', 'morning', 'afternoon', 'evening'
  int? _stackedHabitId;
  int? _goalId;

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

    _habitType = widget.initialHabitType ?? 'boolean';
    _routine = widget.initialRoutine ?? 'anytime';
    _stackedHabitId = widget.initialStackedHabitId;
    _stackTriggerController =
        TextEditingController(text: widget.initialStackTrigger ?? '');
    _goalId = widget.initialGoalId;

    _targetValueController = TextEditingController(
      text: widget.initialTargetValue != null
          ? (widget.initialTargetValue! % 1 == 0
              ? widget.initialTargetValue!.toInt().toString()
              : widget.initialTargetValue!.toString())
          : (_habitType == 'quantity' ? '10' : (_habitType == 'duration' ? '30' : '')),
    );
    _unitController = TextEditingController(
      text: widget.initialUnit ??
          (_habitType == 'quantity' ? 'pages' : (_habitType == 'duration' ? 'mins' : '')),
    );

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

    if (widget.initialScheduleType != null &&
        (widget.initialScheduleType != 'daily' ||
            widget.initialIsReminderEnabled == true ||
            widget.initialStackedHabitId != null ||
            widget.initialGoalId != null ||
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
    _stackTriggerController.dispose();
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

      double? targetVal;
      String? unitStr;
      if (_habitType != 'boolean') {
        targetVal = double.tryParse(_targetValueController.text.trim());
        unitStr = _unitController.text.trim().isNotEmpty
            ? _unitController.text.trim()
            : (_habitType == 'duration' ? 'mins' : 'units');
      }

      final stackTrigger = _stackTriggerController.text.trim().isEmpty
          ? null
          : _stackTriggerController.text.trim();

      Navigator.of(context, rootNavigator: true).pop(
        HabitDialogResult(
          name: name,
          description: desc,
          category: category,
          symbol: _selectedSymbol,
          colorValue: _selectedColor,
          habitType: _habitType,
          routine: _routine,
          stackedHabitId: _stackedHabitId,
          stackTrigger: stackTrigger,
          goalId: _goalId,
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
                      hintText: 'e.g. Morning Water, Read Books, Run',
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

                  // Habit Type Selector (Boolean, Quantity, Duration)
                  const Text('Habit Type',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTypeSegment('boolean', '✓ Boolean', Icons.check_circle_outline),
                        _buildTypeSegment('quantity', '🔢 Quantity', Icons.tag),
                        _buildTypeSegment('duration', '⏱ Duration', Icons.timer_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Numerical Target Section (if Quantity or Duration)
                  if (_habitType != 'boolean') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _habitType == 'duration'
                                    ? 'Daily Target Time'
                                    : 'Daily Target Amount',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _targetValueController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: _habitType == 'duration' ? '30' : '10',
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unit',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _unitController,
                                decoration: InputDecoration(
                                  hintText: _habitType == 'duration' ? 'mins' : 'pages',
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Quick unit suggestions
                    Wrap(
                      spacing: 6,
                      children: (_habitType == 'duration'
                              ? ['mins', 'hours', 'sec']
                              : ['pages', 'glasses', 'reps', 'steps', 'km'])
                          .map((preset) => ActionChip(
                                label: Text(preset, style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setState(() {
                                    _unitController.text = preset;
                                  });
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Routine Selector (Morning, Afternoon, Evening, Anytime)
                  const Text('Routine Timing',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoutineChip('anytime', '⚡ Anytime'),
                        const SizedBox(width: 6),
                        _buildRoutineChip('morning', '🌅 Morning'),
                        const SizedBox(width: 6),
                        _buildRoutineChip('afternoon', '☀️ Afternoon'),
                        const SizedBox(width: 6),
                        _buildRoutineChip('evening', '🌙 Evening'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  const Text('Category',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestedCategories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey[300] : Colors.grey[800]),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

                  // Icon & Color Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon preview & selector
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Icon',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 44,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: HabitSymbols.options.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, idx) {
                                  final opt = HabitSymbols.options[idx];
                                  final isSelected = _selectedSymbol == opt.key;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () =>
                                        setState(() => _selectedSymbol = opt.key),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryColor.withValues(alpha: 0.2)
                                            : (isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(alpha: 0.05)),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(opt.icon,
                                          size: 20,
                                          color: isSelected
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.white70
                                                  : Colors.black54)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Color Palette Picker
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Color',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 44,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: HabitColors.palette.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, idx) {
                                  final colorInt = HabitColors.palette[idx];
                                  final isSelected = _selectedColor == colorInt;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () =>
                                        setState(() => _selectedColor = colorInt),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Color(colorInt),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              size: 18, color: Colors.white)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Advanced Accordion Header
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(
                        () => _isAdvancedExpanded = !_isAdvancedExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAdvancedExpanded
                                    ? Icons.tune
                                    : Icons.tune_outlined,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Advanced Options',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                          Icon(
                            _isAdvancedExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapsible Advanced Settings
                  if (_isAdvancedExpanded) ...[
                    const SizedBox(height: 14),

                    // Habit Stacking Section
                    const Text('Habit Stacking',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Link this habit to be completed right after another habit or trigger.',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    if (widget.availableHabits != null &&
                        widget.availableHabits!.isNotEmpty) ...[
                      DropdownButtonFormField<int?>(
                        initialValue: _stackedHabitId,
                        decoration: InputDecoration(
                          labelText: 'Stack after habit',
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None (Independent Habit)'),
                          ),
                          ...widget.availableHabits!.map(
                            (h) => DropdownMenuItem<int?>(
                              value: h.id,
                              child: Text('After: ${h.name}'),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _stackedHabitId = val),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: _stackTriggerController,
                      decoration: InputDecoration(
                        labelText: 'Or custom anchor cue',
                        hintText: 'e.g. After pouring morning coffee',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Connect to Long-Term Goal
                    if (widget.availableGoals != null &&
                        widget.availableGoals!.isNotEmpty) ...[
                      const Text('Long-Term Goal',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int?>(
                        initialValue: _goalId,
                        decoration: InputDecoration(
                          labelText: 'Connect to Goal',
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...widget.availableGoals!.map(
                            (g) => DropdownMenuItem<int?>(
                              value: g.id,
                              child: Text(g.title),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _goalId = val),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Schedule Type
                    const Text('Schedule',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildScheduleChip('daily', 'Daily'),
                        const SizedBox(width: 8),
                        _buildScheduleChip('specific_days', 'Specific Days'),
                        const SizedBox(width: 8),
                        _buildScheduleChip('weekly_target', 'Times/Week'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Specific Days Picker
                    if (_scheduleType == 'specific_days') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _weekdays.map((item) {
                          final dayNum = item['day'] as int;
                          final isSelected = _selectedDays.contains(dayNum);
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  if (_selectedDays.length > 1) {
                                    _selectedDays.remove(dayNum);
                                  }
                                } else {
                                  _selectedDays.add(dayNum);
                                }
                              });
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? Colors.white10 : Colors.black12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Weekly Target Slider
                    if (_scheduleType == 'weekly_target') ...[
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _weeklyTarget.toDouble(),
                              min: 1,
                              max: 7,
                              divisions: 6,
                              activeColor: primaryColor,
                              onChanged: (val) =>
                                  setState(() => _weeklyTarget = val.round()),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_weeklyTarget days / week',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Reminder Notification Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reminder Notification',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Switch(
                          value: _isReminderEnabled,
                          activeThumbColor: primaryColor,
                          onChanged: (val) =>
                              setState(() => _isReminderEnabled = val),
                        ),
                      ],
                    ),
                    if (_isReminderEnabled) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTimeOfDay ??
                                const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => _reminderTimeOfDay = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Reminder Time',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                _reminderTimeOfDay?.format(context) ?? '08:00 AM',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                          label: Text(DateFormat('MMM d, y').format(_startDate)),
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
                    const SizedBox(height: 10),

                    // Description Input
                    const Text('Description (Optional)',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add extra motivation or guidelines...',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        child: Text(widget.confirmLabel),
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

  Widget _buildTypeSegment(String type, String label, IconData icon) {
    final isSelected = _habitType == type;
    final primaryColor = Color(_selectedColor);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _habitType = type;
            if (type == 'quantity' && _unitController.text.isEmpty) {
              _unitController.text = 'pages';
              _targetValueController.text = '10';
            } else if (type == 'duration' && _unitController.text.isEmpty) {
              _unitController.text = 'mins';
              _targetValueController.text = '30';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineChip(String routine, String label) {
    final isSelected = _routine == routine;
    final primaryColor = Color(_selectedColor);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (selected) {
        if (selected) setState(() => _routine = routine);
      },
    );
  }

  Widget _buildScheduleChip(String type, String label) {
    final isSelected = _scheduleType == type;
    final primaryColor = Color(_selectedColor);
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (selected) {
          if (selected) setState(() => _scheduleType = type);
        },
      ),
    );
  }
}
