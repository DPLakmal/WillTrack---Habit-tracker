import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/database.dart';
import '../../providers/habit_provider.dart';
import '../widgets/apple_glass_card.dart';
import '../widgets/difficulty_selector.dart';
import '../widgets/habit_analytics_section.dart';
import '../widgets/habit_dialog.dart';
import '../widgets/habit_symbol_icon.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late DateTime _displayedMonth;
  late Habit _currentHabit;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _showDayLogSheet(
    BuildContext context,
    DateTime date,
    CheckIn? checkIn,
    HabitProvider provider,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final noteController = TextEditingController(text: checkIn?.note ?? '');
    String selectedStatus = checkIn?.status ?? 'none';
    int selectedDifficulty = checkIn?.difficulty ?? 5;
    final habitColor = Color(_currentHabit.colorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AppleGlassCard(
              borderRadius: 32,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 22,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(date),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          avatar: Icon(
                            HabitSymbols.getIcon(_currentHabit.symbol),
                            size: 16,
                            color: selectedStatus == 'completed'
                                ? Colors.white
                                : habitColor,
                          ),
                          label: const Text('Completed'),
                          selected: selectedStatus == 'completed',
                          selectedColor: habitColor,
                          onSelected: (val) {
                            setSheetState(() {
                              selectedStatus = val ? 'completed' : 'none';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.remove_circle_outline, size: 16),
                          label: const Text('Skipped'),
                          selected: selectedStatus == 'skipped',
                          onSelected: (val) {
                            setSheetState(() {
                              selectedStatus = val ? 'skipped' : 'none';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Unmarked'),
                          selected: selectedStatus == 'none',
                          onSelected: (val) {
                            setSheetState(() {
                              selectedStatus = 'none';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (selectedStatus == 'completed') ...[
                      DifficultySelector(
                        selectedDifficulty: selectedDifficulty,
                        onChanged: (val) {
                          setSheetState(() {
                            selectedDifficulty = val;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                    ],

                    const Text(
                      'What did you do? / Day Notes',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Swam 1000m freestyle, felt energetic!',
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: habitColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await provider.updateDayLog(
                            _currentHabit.id,
                            dateStr,
                            status: selectedStatus,
                            difficulty: selectedStatus == 'completed'
                                ? selectedDifficulty
                                : null,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: const Text(
                          'Save Status & Notes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editHabit(BuildContext context, HabitProvider provider) async {
    final result = await showDialog<HabitDialogResult>(
      context: context,
      builder: (ctx) => HabitDialog(
        title: 'Edit Habit',
        initialName: _currentHabit.name,
        initialCategory: _currentHabit.category,
        initialSymbol: _currentHabit.symbol,
        initialColor: _currentHabit.colorValue,
        confirmLabel: 'Update',
      ),
    );

    if (result != null) {
      await provider.editHabit(
        _currentHabit.id,
        result.name,
        category: result.category,
        symbol: result.symbol,
        colorValue: result.colorValue,
      );

      final updated = await provider.database.getHabitById(_currentHabit.id);
      if (updated != null && mounted) {
        setState(() {
          _currentHabit = updated;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(_currentHabit.colorValue);
    final symbolIcon = HabitSymbols.getIcon(_currentHabit.symbol);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_currentHabit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editHabit(context, provider),
            tooltip: 'Edit Habit',
          ),
        ],
      ),
      body: AppleGlassBackground(
        child: SafeArea(
          child: StreamBuilder<List<CheckIn>>(
            stream: provider.watchHabitHistory(_currentHabit.id),
            builder: (context, snapshot) {
              final history = snapshot.data ?? [];
              final Map<String, CheckIn> checkInMap = {
                for (var c in history) c.date: c,
              };

              final stats = provider.computeHabitStats(history);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Glass Card
                    AppleGlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  habitColor.withValues(alpha: 0.25),
                                  habitColor.withValues(alpha: 0.12),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: habitColor.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(symbolIcon, color: habitColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: habitColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _currentHabit.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: habitColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${stats.totalCompletions} Day${stats.totalCompletions == 1 ? '' : 's'} Completed',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Calendar Glass Card
                    AppleGlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _previousMonth,
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_displayedMonth),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _nextMonth,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Weekday labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                                .map(
                                  (day) => SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 10),

                          _buildMonthGrid(
                            context,
                            _displayedMonth,
                            checkInMap,
                            habitColor,
                            symbolIcon,
                            provider,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress & Difficulty Analysis Section
                    HabitAnalyticsSection(
                      habit: _currentHabit,
                      stats: stats,
                    ),
                    const SizedBox(height: 20),

                    // Activity & Notes
                    Text(
                      'RECENT ACTIVITY & NOTES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (history.where((c) => c.note != null && c.note!.isNotEmpty).isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Tap any day in the calendar to record notes or difficulty!',
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ...history
                          .where((c) => c.note != null && c.note!.isNotEmpty)
                          .take(10)
                          .map((c) {
                        final itemDate = DateFormat('yyyy-MM-dd').parse(c.date);
                        final diffColor = c.difficulty != null
                            ? DifficultySelector.getColorForDifficulty(c.difficulty!)
                            : habitColor;

                        return AppleGlassCard(
                          borderRadius: 18,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: c.status == 'completed'
                                    ? habitColor.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                child: Icon(
                                  c.status == 'completed' ? symbolIcon : Icons.skip_next,
                                  color: c.status == 'completed' ? habitColor : Colors.orange,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          DateFormat('EEEE, MMM d').format(itemDate),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                        if (c.difficulty != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: diffColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${c.difficulty}/10',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: diffColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.note ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_note, size: 22),
                                onPressed: () => _showDayLogSheet(
                                  context,
                                  itemDate,
                                  c,
                                  provider,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    DateTime month,
    Map<String, CheckIn> checkIns,
    Color habitColor,
    IconData symbolIcon,
    HabitProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(month.year, month.month, dayNumber);
        final cellDateStr = DateFormat('yyyy-MM-dd').format(cellDate);
        final checkIn = checkIns[cellDateStr];
        final isCompleted = checkIn?.status == 'completed';
        final isSkipped = checkIn?.status == 'skipped';
        final hasNote = checkIn?.note != null && checkIn!.note!.isNotEmpty;
        final hasDifficulty = checkIn?.difficulty != null;
        final isToday = cellDateStr == todayStr;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showDayLogSheet(context, cellDate, checkIn, provider),
          child: Container(
            decoration: BoxDecoration(
              color: isCompleted
                  ? habitColor
                  : isSkipped
                      ? (isDark ? Colors.grey[800] : Colors.grey[200])
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(10),
              border: isToday
                  ? Border.all(color: habitColor, width: 2)
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.7),
                      width: 1,
                    ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: habitColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isCompleted)
                  Icon(
                    symbolIcon,
                    color: Colors.white,
                    size: 16,
                  )
                else
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: isSkipped
                          ? Colors.grey
                          : (isDark ? Colors.grey[300] : Colors.grey[800]),
                    ),
                  ),

                if (hasNote || hasDifficulty)
                  Positioned(
                    bottom: 3,
                    right: 4,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? (checkIn?.difficulty != null
                                ? DifficultySelector.getColorForDifficulty(
                                    checkIn!.difficulty!)
                                : Colors.white)
                            : habitColor,
                        shape: BoxShape.circle,
                        border: isCompleted
                            ? Border.all(color: Colors.white, width: 0.5)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
