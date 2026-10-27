import 'package:flutter/material.dart';
import '../../providers/habit_provider.dart';

class HabitTile extends StatelessWidget {
  final HabitItem habitItem;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitTile({
    super.key,
    required this.habitItem,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = habitItem.isCompletedToday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDone
                    ? Colors.green.withValues(alpha: 0.3)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Checkmark / Circle button
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? Colors.green
                            : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Habit Title
                Expanded(
                  child: Text(
                    habitItem.habit.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                      decoration:
                          isDone ? TextDecoration.lineThrough : TextDecoration.none,
                      color: isDone
                          ? (isDark ? Colors.grey[500] : Colors.grey[400])
                          : (isDark ? Colors.grey[100] : const Color(0xFF1F2937)),
                    ),
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
          ),
        ),
      ),
    );
  }
}
