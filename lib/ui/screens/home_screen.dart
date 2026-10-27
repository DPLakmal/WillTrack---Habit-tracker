import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database.dart';
import '../../providers/habit_provider.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/habit_dialog.dart';
import '../widgets/habit_tile.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showAddHabitDialog(BuildContext context) async {
    final provider = context.read<HabitProvider>();
    final result = await showDialog<HabitDialogResult>(
      context: context,
      builder: (ctx) => const HabitDialog(
        title: 'New Habit',
        confirmLabel: 'Add Habit',
      ),
    );

    if (result != null && result.name.isNotEmpty) {
      await provider.addHabit(
        result.name,
        category: result.category,
        symbol: result.symbol,
        colorValue: result.colorValue,
      );
    }
  }

  Future<void> _showEditHabitDialog(
      BuildContext context, Habit habit) async {
    final provider = context.read<HabitProvider>();
    final result = await showDialog<HabitDialogResult>(
      context: context,
      builder: (ctx) => HabitDialog(
        title: 'Edit Habit',
        initialName: habit.name,
        initialCategory: habit.category,
        initialSymbol: habit.symbol,
        initialColor: habit.colorValue,
        confirmLabel: 'Update',
      ),
    );

    if (result != null && result.name.isNotEmpty) {
      await provider.editHabit(
        habit.id,
        result.name,
        category: result.category,
        symbol: result.symbol,
        colorValue: result.colorValue,
      );
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
    final allHabits = provider.allHabitItems;
    final categories = provider.categories;
    final selectedCategory = provider.selectedCategory;
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
        child: allHabits.isEmpty
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

                  // Category Filter Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  provider.setSelectedCategory(cat);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Section Header: "TODAY'S HABITS"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedCategory == 'All'
                                ? "TODAY'S HABITS"
                                : "${selectedCategory.toUpperCase()} HABITS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${habitItems.length} habit${habitItems.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Habit items list
                  if (habitItems.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No habits in "$selectedCategory" category',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = habitItems[index];
                          return HabitTile(
                            habitItem: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HabitDetailScreen(habit: item.habit),
                                ),
                              );
                            },
                            onToggle: () =>
                                provider.toggleHabitCompletion(item.habit.id),
                            onEdit: () => _showEditHabitDialog(
                                context, item.habit),
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
