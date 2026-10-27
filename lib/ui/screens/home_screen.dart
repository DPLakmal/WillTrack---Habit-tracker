import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database.dart';
import '../../providers/habit_provider.dart';
import '../widgets/apple_glass_card.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Habits'),
        actions: [
          // Apple Glass Theme Toggle Pill
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              child: IconButton(
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                tooltip: 'Toggle Theme',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => provider.toggleTheme(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: FilledButton.icon(
              onPressed: () => _showAddHabitDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: AppleGlassBackground(
        child: SafeArea(
          child: allHabits.isEmpty
              ? EmptyStateWidget(onAddHabit: () => _showAddHabitDialog(context))
              : CustomScrollView(
                  slivers: [
                    // Daily Progress Glass Card
                    SliverToBoxAdapter(
                      child: DailyProgressCard(
                        completed: provider.completedCount,
                        total: provider.totalCount,
                        progress: provider.progressPercentage,
                        percentage: provider.progressPercentInt,
                      ),
                    ),

                    // iOS Glass Filter Chips
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
                                selectedColor: const Color(0xFF10B981),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569)),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.white.withValues(alpha: 0.8)),
                                ),
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.5),
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
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${habitItems.length} habit${habitItems.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
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
                            child: AppleGlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              borderRadius: 16,
                              child: Text(
                                'No habits in "$selectedCategory" category',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
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
                              onSelectDifficulty: (score) =>
                                  provider.markHabitDifficulty(item.habit.id, score),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: () => _showAddHabitDialog(context),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Habit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
