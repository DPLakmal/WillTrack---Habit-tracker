import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/database.dart';
import '../../providers/habit_provider.dart';
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
    final habitColor = Color(_currentHabit.colorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                  const Text(
                    'What did you do? / Day Notes',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Swam 1000m freestyle, felt energetic!',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await provider.updateDayLog(
                          _currentHabit.id,
                          dateStr,
                          status: selectedStatus,
                          note: noteController.text.trim().isEmpty
                              ? null
                              : noteController.text.trim(),
                        );
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: const Text('Save Status & Notes'),
                    ),
                  ),
                ],
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
      body: StreamBuilder<List<CheckIn>>(
        stream: provider.watchHabitHistory(_currentHabit.id),
        builder: (context, snapshot) {
          final history = snapshot.data ?? [];
          final Map<String, CheckIn> checkInMap = {
            for (var c in history) c.date: c,
          };

          // Compute Retention / Streaks
          final completedDates = history
              .where((c) => c.status == 'completed')
              .map((c) => c.date)
              .toSet();

          final totalCompletions = completedDates.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card with Symbol & Retention Stats
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: habitColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
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
                                '$totalCompletions Day${totalCompletions == 1 ? '' : 's'} Completed',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Calendar Card
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Month Navigation Header
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _nextMonth,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Weekday labels (Sun - Sat)
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
                        const SizedBox(height: 8),

                        // Month Grid
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
                ),
                const SizedBox(height: 20),

                // Notes & Activity History
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
                        'Tap any day in the calendar to record what you did!',
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
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c.status == 'completed'
                              ? habitColor.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          child: Icon(
                            c.status == 'completed' ? symbolIcon : Icons.skip_next,
                            color: c.status == 'completed' ? habitColor : Colors.orange,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          DateFormat('EEEE, MMM d').format(itemDate),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          c.note ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note, size: 20),
                          onPressed: () => _showDayLogSheet(
                            context,
                            itemDate,
                            c,
                            provider,
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
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
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
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
        final isToday = cellDateStr == todayStr;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showDayLogSheet(context, cellDate, checkIn, provider),
          child: Container(
            decoration: BoxDecoration(
              color: isCompleted
                  ? habitColor
                  : isSkipped
                      ? (isDark ? Colors.grey[800] : Colors.grey[200])
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: habitColor, width: 2)
                  : Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      width: 1,
                    ),
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
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSkipped
                          ? Colors.grey
                          : (isDark ? Colors.grey[300] : Colors.grey[800]),
                    ),
                  ),

                // Note dot indicator
                if (hasNote)
                  Positioned(
                    bottom: 3,
                    right: 4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.white : habitColor,
                        shape: BoxShape.circle,
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
