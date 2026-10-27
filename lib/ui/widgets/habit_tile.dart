import 'package:flutter/material.dart';
import '../../providers/habit_provider.dart';
import 'apple_glass_card.dart';
import 'difficulty_selector.dart';
import 'habit_symbol_icon.dart';

class HabitTile extends StatelessWidget {
  final HabitItem habitItem;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectDifficulty;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const HabitTile({
    super.key,
    required this.habitItem,
    required this.onTap,
    required this.onToggle,
    required this.onSelectDifficulty,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = habitItem.isCompletedToday;
    final habit = habitItem.habit;
    final habitColor = Color(habit.colorValue);
    final symbolIcon = HabitSymbols.getIcon(habit.symbol);
    final todayDifficulty = habitItem.todayDifficulty;

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
            children: [
              // Glass Check Button
              GestureDetector(
                key: const Key('habit_toggle_button'),
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: 36,
                  height: 36,
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

              // Title and category badge
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
                    const SizedBox(height: 4),
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
                                  fontSize: 11,
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

                        // Reminder badge if active
                        if (habit.isReminderEnabled &&
                            habit.reminderTime != null &&
                            habit.reminderTime!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  size: 11,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  habit.reminderTime!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
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
                                fontSize: 11,
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
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, size: 18, color: Color(0xFFF59E0B)),
                        SizedBox(width: 10),
                        Text('Archive', style: TextStyle(color: Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

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
