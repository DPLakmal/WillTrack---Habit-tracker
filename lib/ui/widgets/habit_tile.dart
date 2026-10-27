import 'package:flutter/material.dart';
import '../../providers/habit_provider.dart';
import 'apple_glass_card.dart';
import 'difficulty_selector.dart';
import 'habit_symbol_icon.dart';
import 'quantity_duration_stepper.dart';

class HabitTile extends StatelessWidget {
  final HabitItem habitItem;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectDifficulty;
  final ValueChanged<double>? onIncrementQuantity;
  final ValueChanged<double>? onSetQuantity;
  final ValueChanged<double>? onAddDurationMinutes;
  final VoidCallback? onAddNote;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const HabitTile({
    super.key,
    required this.habitItem,
    required this.onTap,
    required this.onToggle,
    required this.onSelectDifficulty,
    this.onIncrementQuantity,
    this.onSetQuantity,
    this.onAddDurationMinutes,
    this.onAddNote,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  String _formatSchedule(String type, String days, int target) {
    if (type == 'daily') return 'Daily';
    if (type == 'weekly_target') return '${target}x / week';
    if (type == 'specific_days') {
      const names = {
        1: 'Mon',
        2: 'Tue',
        3: 'Wed',
        4: 'Thu',
        5: 'Fri',
        6: 'Sat',
        7: 'Sun'
      };
      final parsed = days
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .map((d) => names[d] ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      return parsed.isEmpty ? 'Scheduled' : parsed.join(', ');
    }
    return 'Daily';
  }

  String _getRoutineLabel(String routine) {
    switch (routine.toLowerCase()) {
      case 'morning':
        return '🌅 Morning';
      case 'afternoon':
        return '☀️ Afternoon';
      case 'evening':
        return '🌙 Evening';
      default:
        return '⚡ Anytime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = habitItem.isCompletedToday;
    final habit = habitItem.habit;
    final habitColor = Color(habit.colorValue);
    final symbolIcon = HabitSymbols.getIcon(habit.symbol);
    final todayDifficulty = habitItem.todayDifficulty;
    final isQuantity = habitItem.isQuantity;
    final isDuration = habitItem.isDuration;

    return AppleGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      borderRadius: 22,
      padding: const EdgeInsets.all(15),
      border: Border.all(
        color: isDone
            ? habitColor.withValues(alpha: 0.5)
            : (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.8)),
        width: isDone ? 1.5 : 1.0,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glass Check Button (or Icon indicator)
              GestureDetector(
                key: const Key('habit_toggle_button'),
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDone
                        ? LinearGradient(
                            colors: [
                              habitColor.withValues(alpha: 0.85),
                              habitColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isDone
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04)),
                    border: Border.all(
                      color: isDone
                          ? Colors.white.withValues(alpha: 0.6)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.2)),
                      width: 1.8,
                    ),
                    boxShadow: isDone
                        ? [
                            BoxShadow(
                              color: habitColor.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: isDone
                      ? Icon(
                          symbolIcon,
                          size: 19,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isDone ? FontWeight.w500 : FontWeight.w700,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isDone
                            ? (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8))
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Badges Wrap (Category, Routine, Schedule, Stack, Goal)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: habitColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: habitColor.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: habitColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        // Routine pill (if not anytime)
                        if (habit.routine != 'anytime')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _getRoutineLabel(habit.routine),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),

                        // Schedule badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 10,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatSchedule(
                                  habit.scheduleType,
                                  habit.scheduleDays,
                                  habit.weeklyTargetDays,
                                ),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Habit Stacking Cue Pill
                        if (habitItem.isStacked) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: habitItem.isStackAnchorCompleted
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.18)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: habitItem.isStackAnchorCompleted
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.4)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.08)),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  size: 11,
                                  color: habitItem.isStackAnchorCompleted
                                      ? const Color(0xFF10B981)
                                      : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  habitItem.stackedHabitName != null
                                      ? 'After: ${habitItem.stackedHabitName!}'
                                      : (habit.stackTrigger ?? 'Stacked'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: habitItem.isStackAnchorCompleted
                                        ? const Color(0xFF10B981)
                                        : (isDark
                                            ? const Color(0xFFCBD5E1)
                                            : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Linked Goal Tag
                        if (habitItem.linkedGoalTitle != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.flag_outlined,
                                  size: 10,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  habitItem.linkedGoalTitle!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Note icon if a note is attached today
                        if (habitItem.todayNote != null &&
                            habitItem.todayNote!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 10,
                                  color: Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  habitItem.todayNote!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (isDone && todayDifficulty != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: DifficultySelector.getColorForDifficulty(
                                      todayDifficulty)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: DifficultySelector.getColorForDifficulty(
                                        todayDifficulty)
                                    .withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'Diff: $todayDifficulty/10',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: DifficultySelector.getColorForDifficulty(
                                    todayDifficulty),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Glass menu icon
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  size: 22,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'note') {
                    onAddNote?.call();
                  } else if (value == 'archive') {
                    onArchive();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'note',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, size: 18, color: Color(0xFF3B82F6)),
                        SizedBox(width: 10),
                        Text('Add Note', style: TextStyle(color: Color(0xFF3B82F6))),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined,
                            size: 18, color: Color(0xFFF59E0B)),
                        SizedBox(width: 10),
                        Text('Archive',
                            style: TextStyle(color: Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Interactive Stepper for Quantity Habits
          if (isQuantity && onIncrementQuantity != null && onSetQuantity != null) ...[
            const SizedBox(height: 12),
            QuantityStepper(
              currentLogged: habitItem.todayValueLogged ?? 0.0,
              targetValue: habit.targetValue ?? 0.0,
              unit: habit.unit ?? 'units',
              activeColor: habitColor,
              onIncrement: onIncrementQuantity!,
              onSetValue: onSetQuantity!,
            ),
          ],

          // Interactive Stepper for Duration Habits
          if (isDuration && onAddDurationMinutes != null) ...[
            const SizedBox(height: 12),
            DurationStepper(
              currentLogged: habitItem.todayValueLogged ?? 0.0,
              targetMinutes: habit.targetValue ?? 0.0,
              unit: habit.unit ?? 'mins',
              activeColor: habitColor,
              onAddMinutes: onAddDurationMinutes!,
            ),
          ],

          const SizedBox(height: 12),

          // Rating effort prompt
          Row(
            children: [
              Text(
                'Rate effort today:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              if (todayDifficulty != null)
                Text(
                  DifficultySelector.getLabelForDifficulty(todayDifficulty),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DifficultySelector.getColorForDifficulty(
                        todayDifficulty),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 1-10 Apple Glass Number Pills
          SizedBox(
            height: 32,
            child: Row(
              children: List.generate(10, (idx) {
                final score = idx + 1;
                final isSelected = todayDifficulty == score;
                final color = DifficultySelector.getColorForDifficulty(score);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: InkWell(
                      key: Key('diff_button_${habit.id}_$score'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onSelectDifficulty(score),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.white.withValues(alpha: 0.60)),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
