import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/habit_dialog.dart';
import '../widgets/habit_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showAddHabitDialog(BuildContext context) async {
    final provider = context.read<HabitProvider>();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => const HabitDialog(
        title: 'New Habit',
        confirmLabel: 'Add Habit',
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await provider.addHabit(newName);
    }
  }

  Future<void> _showEditHabitDialog(
      BuildContext context, int habitId, String currentName) async {
    final provider = context.read<HabitProvider>();
    final updatedName = await showDialog<String>(
      context: context,
      builder: (ctx) => HabitDialog(
        title: 'Edit Habit',
        initialName: currentName,
        confirmLabel: 'Update',
      ),
    );

    if (updatedName != null && updatedName.isNotEmpty) {
      await provider.editHabit(habitId, updatedName);
    }
  }

  Future<void> _confirmDeleteHabit(
      BuildContext context, int habitId, String habitName) async {
    final provider = context.read<HabitProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "$habitName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteHabit(habitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habitItems = provider.habitItems;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => provider.toggleTheme(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showAddHabitDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: habitItems.isEmpty
            ? EmptyStateWidget(onAddHabit: () => _showAddHabitDialog(context))
            : CustomScrollView(
                slivers: [
                  // Daily Progress Card
                  SliverToBoxAdapter(
                    child: DailyProgressCard(
                      completed: provider.completedCount,
                      total: provider.totalCount,
                      progress: provider.progressPercentage,
                      percentage: provider.progressPercentInt,
                    ),
                  ),

                  // Section Header: "TODAY'S HABITS"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        "TODAY'S HABITS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // Habit items list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = habitItems[index];
                        return HabitTile(
                          habitItem: item,
                          onToggle: () =>
                              provider.toggleHabitCompletion(item.habit.id),
                          onEdit: () => _showEditHabitDialog(
                              context, item.habit.id, item.habit.name),
                          onDelete: () => _confirmDeleteHabit(
                              context, item.habit.id, item.habit.name),
                        );
                      },
                      childCount: habitItems.length,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }
}
