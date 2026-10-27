import 'package:flutter/material.dart';
import '../../providers/habit_provider.dart';
import 'difficulty_selector.dart';
import 'habit_symbol_icon.dart';

class HabitTile extends StatelessWidget {
  final HabitItem habitItem;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectDifficulty;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitTile({
    super.key,
    required this.habitItem,
    required this.onTap,
    required this.onToggle,
    required this.onSelectDifficulty,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = habitItem.isCompletedToday;
    final habit = habitItem.habit;
    final habitColor = Color(habit.colorValue);
    final symbolIcon = HabitSymbols.getIcon(habit.symbol);
    final todayDifficulty = habitItem.todayDifficulty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? habitColor.withValues(alpha: 0.4)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                width: isDone ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Row: Checkmark, Title, Category, Difficulty badge, Menu
                Row(
                  children: [
                    // Toggle Circle / Icon
                    GestureDetector(
                      key: const Key('habit_toggle_button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? habitColor : Colors.transparent,
                          border: Border.all(
                            color: isDone
                                ? habitColor
                                : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                            width: 2,
                          ),
                        ),
                        child: isDone
                            ? Icon(
                                symbolIcon,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Habit Name & Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isDone
                                  ? (isDark ? Colors.grey[500] : Colors.grey[400])
                                  : (isDark ? Colors.grey[100] : const Color(0xFF1F2937)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: habitColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  habit.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: habitColor,
                                  ),
                                ),
                              ),
                              if (isDone && todayDifficulty != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: DifficultySelector.getColorForDifficulty(
                                            todayDifficulty)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Diff: $todayDifficulty/10',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: DifficultySelector.getColorForDifficulty(
                                          todayDifficulty),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
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
                const SizedBox(height: 12),

                // Inline 1-10 Difficulty Selection Row
                Row(
                  children: [
                    Text(
                      'Rate effort today:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (todayDifficulty != null)
                      Text(
                        DifficultySelector.getLabelForDifficulty(todayDifficulty),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: DifficultySelector.getColorForDifficulty(
                              todayDifficulty),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // 1-10 Selector Pill Row
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
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => onSelectDifficulty(score),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : (isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : (isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[700]),
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
          ),
        ),
      ),
    );
  }
}
