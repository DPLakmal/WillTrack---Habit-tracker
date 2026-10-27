import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import 'apple_glass_card.dart';
import 'habit_symbol_icon.dart';

class GoalsSheet extends StatelessWidget {
  final List<Goal> goals;
  final List<Habit> habits;
  final Function(String title, String? desc, String category, int color, DateTime? targetDate) onAddGoal;
  final Function(int id) onDeleteGoal;

  const GoalsSheet({
    super.key,
    required this.goals,
    required this.habits,
    required this.onAddGoal,
    required this.onDeleteGoal,
  });

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int selectedColor = HabitColors.palette[0];
    String selectedCategory = 'Fitness';
    DateTime? targetDate = DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Text('New Long-Term Goal',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Goal Title',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Run 10K, Read 20 Books',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Category',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Fitness', 'Learning', 'Health', 'Productivity', 'General']
                        .map((cat) => ChoiceChip(
                              label: Text(cat, style: const TextStyle(fontSize: 11)),
                              selected: selectedCategory == cat,
                              selectedColor: Color(selectedColor),
                              labelStyle: TextStyle(
                                color: selectedCategory == cat ? Colors.white : null,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => selectedCategory = cat);
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Target Date (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: targetDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => targetDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            targetDate != null
                                ? DateFormat('MMM d, y').format(targetDate!)
                                : 'Select Date',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Color(selectedColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    onAddGoal(
                      title,
                      descController.text.trim().isEmpty ? null : descController.text.trim(),
                      selectedCategory,
                      selectedColor,
                      targetDate,
                    );
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Create Goal'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🎯 Long-Term Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Goal', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddGoalDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (goals.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(Icons.flag_outlined, size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 10),
                        const Text(
                          'No active long-term goals yet',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a goal and link habits to track broader life milestones.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: goals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final goal = goals[idx];
                      final linkedHabits = habits.where((h) => h.goalId == goal.id).toList();
                      final color = Color(goal.colorValue);

                      return AppleGlassCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.track_changes, size: 18, color: color),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (goal.targetDate != null)
                                          Text(
                                            'Target: ${DateFormat('MMM d, y').format(goal.targetDate!)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => onDeleteGoal(goal.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Linked Habits Tags
                            Row(
                              children: [
                                Text(
                                  'Linked Habits (${linkedHabits.length}): ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                if (linkedHabits.isEmpty)
                                  Text(
                                    'None yet (assign in Habit options)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: linkedHabits.map((h) {
                                          return Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Color(h.colorValue).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              h.name,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(h.colorValue),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
