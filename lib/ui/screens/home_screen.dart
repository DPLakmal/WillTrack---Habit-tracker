import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database.dart';
import '../../providers/habit_provider.dart';
import '../widgets/achievements_sheet.dart';
import '../widgets/apple_glass_card.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/goals_sheet.dart';
import '../widgets/habit_dialog.dart';
import '../widgets/habit_tile.dart';
import '../widgets/weekly_review_sheet.dart';
import 'habit_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showAddHabitDialog(BuildContext context) async {
    final provider = context.read<HabitProvider>();
    final result = await showDialog<HabitDialogResult>(
      context: context,
      builder: (ctx) => HabitDialog(
        title: 'New Habit',
        confirmLabel: 'Add Habit',
        availableHabits: provider.allHabitItems.map((i) => i.habit).toList(),
        availableGoals: provider.goals,
      ),
    );

    if (result != null && result.name.isNotEmpty) {
      await provider.addHabit(
        result.name,
        description: result.description,
        category: result.category,
        symbol: result.symbol,
        colorValue: result.colorValue,
        habitType: result.habitType,
        routine: result.routine,
        stackedHabitId: result.stackedHabitId,
        stackTrigger: result.stackTrigger,
        goalId: result.goalId,
        scheduleType: result.scheduleType,
        scheduleDays: result.scheduleDays,
        weeklyTargetDays: result.weeklyTargetDays,
        startDate: result.startDate,
        targetValue: result.targetValue,
        unit: result.unit,
        reminderTime: result.reminderTime,
        isReminderEnabled: result.isReminderEnabled,
      );
    }
  }

  Future<void> _showEditHabitDialog(BuildContext context, Habit habit) async {
    final provider = context.read<HabitProvider>();
    final otherHabits = provider.allHabitItems
        .map((i) => i.habit)
        .where((h) => h.id != habit.id)
        .toList();

    final result = await showDialog<HabitDialogResult>(
      context: context,
      builder: (ctx) => HabitDialog(
        title: 'Edit Habit',
        initialName: habit.name,
        initialDescription: habit.description,
        initialCategory: habit.category,
        initialSymbol: habit.symbol,
        initialColor: habit.colorValue,
        initialHabitType: habit.habitType,
        initialRoutine: habit.routine,
        initialStackedHabitId: habit.stackedHabitId,
        initialStackTrigger: habit.stackTrigger,
        initialGoalId: habit.goalId,
        initialScheduleType: habit.scheduleType,
        initialScheduleDays: habit.scheduleDays,
        initialWeeklyTargetDays: habit.weeklyTargetDays,
        initialStartDate: habit.startDate,
        initialTargetValue: habit.targetValue,
        initialUnit: habit.unit,
        initialReminderTime: habit.reminderTime,
        initialIsReminderEnabled: habit.isReminderEnabled,
        availableHabits: otherHabits,
        availableGoals: provider.goals,
        confirmLabel: 'Update',
      ),
    );

    if (result != null && result.name.isNotEmpty) {
      await provider.editHabit(
        habit.id,
        result.name,
        description: result.description,
        category: result.category,
        symbol: result.symbol,
        colorValue: result.colorValue,
        habitType: result.habitType,
        routine: result.routine,
        stackedHabitId: result.stackedHabitId,
        stackTrigger: result.stackTrigger,
        goalId: result.goalId,
        scheduleType: result.scheduleType,
        scheduleDays: result.scheduleDays,
        weeklyTargetDays: result.weeklyTargetDays,
        startDate: result.startDate,
        targetValue: result.targetValue,
        unit: result.unit,
        reminderTime: result.reminderTime,
        isReminderEnabled: result.isReminderEnabled,
      );
    }
  }

  Future<void> _showAddNoteDialog(
      BuildContext context, int habitId, String? currentNote) async {
    final provider = context.read<HabitProvider>();
    final controller = TextEditingController(text: currentNote ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Check-in Note',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Record thoughts, reflections, or obstacles...',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await provider.attachNoteToCheckIn(
        habitId,
        provider.todayString,
        controller.text,
      );
    }
  }

  Future<void> _archiveHabit(BuildContext context, Habit habit) async {
    final provider = context.read<HabitProvider>();
    await provider.archiveHabit(habit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archived "${habit.name}"'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => provider.unarchiveHabit(habit.id),
          ),
        ),
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

  void _openAchievements(BuildContext context, HabitProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementsSheet(achievements: provider.achievements),
    );
  }

  Future<void> _openWeeklyReview(
      BuildContext context, HabitProvider provider) async {
    final reviewData = await provider.computeOverallWeeklyReview();
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WeeklyReviewSheet(reviewData: reviewData),
      );
    }
  }

  void _openGoals(BuildContext context, HabitProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalsSheet(
        goals: provider.goals,
        habits: provider.allHabitItems.map((i) => i.habit).toList(),
        onAddGoal: (title, desc, cat, color, target) =>
            provider.addGoal(title,
                description: desc,
                category: cat,
                colorValue: color,
                targetDate: target),
        onDeleteGoal: (id) => provider.deleteGoal(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habitItems = provider.habitItems;
    final allHabits = provider.allHabitItems;
    final categories = provider.categories;
    final selectedCategory = provider.selectedCategory;
    final routines = provider.routines;
    final selectedRoutine = provider.selectedRoutine;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Trigger celebration if an achievement unlocked
    if (provider.latestUnlockedAchievement != null) {
      final name = provider.latestUnlockedAchievement!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🎉 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Achievement Unlocked: $name!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 4),
          ),
        );
        provider.clearLatestAchievement();
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('WillTrack'),
        actions: [
          // Weekly Review Pill Button
          _HeaderIconButton(
            icon: Icons.bar_chart_rounded,
            tooltip: 'Weekly Review',
            isDark: isDark,
            onPressed: () => _openWeeklyReview(context, provider),
          ),
          // Goals Pill Button
          _HeaderIconButton(
            icon: Icons.flag_outlined,
            tooltip: 'Long-Term Goals',
            isDark: isDark,
            onPressed: () => _openGoals(context, provider),
          ),
          // Achievements Pill Button
          _HeaderIconButton(
            icon: Icons.emoji_events_outlined,
            tooltip: 'Achievements',
            isDark: isDark,
            badgeCount: provider.unlockedAchievementsCount > 0
                ? provider.unlockedAchievementsCount
                : null,
            onPressed: () => _openAchievements(context, provider),
          ),
          // Settings Pill
          _HeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            isDark: isDark,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          // Apple Glass Theme Toggle Pill
          _HeaderIconButton(
            icon: isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            tooltip: 'Toggle Theme',
            isDark: isDark,
            onPressed: () => provider.toggleTheme(),
          ),
          const SizedBox(width: 8),
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

                    // Routine Filter Selector (Morning, Afternoon, Evening, Anytime)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                        child: SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: routines.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final r = routines[index];
                              final isSelected =
                                  selectedRoutine.toLowerCase() ==
                                      r.toLowerCase();
                              String label = r;
                              if (r == 'Morning') label = '🌅 Morning';
                              if (r == 'Afternoon') label = '☀️ Afternoon';
                              if (r == 'Evening') label = '🌙 Evening';
                              if (r == 'Anytime') label = '⚡ Anytime';

                              return ChoiceChip(
                                label: Text(label),
                                selected: isSelected,
                                selectedColor: const Color(0xFF3B82F6),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569)),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.white.withValues(alpha: 0.7)),
                                ),
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.4),
                                onSelected: (selected) {
                                  if (selected) {
                                    provider.setSelectedRoutine(r);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Category Filter Chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected =
                                  selectedCategory.toLowerCase() ==
                                      cat.toLowerCase();
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: const Color(0xFF10B981),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569)),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.white.withValues(alpha: 0.7)),
                                ),
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.4),
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
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedRoutine != 'All'
                                  ? "${selectedRoutine.toUpperCase()} ROUTINE"
                                  : (selectedCategory == 'All'
                                      ? "TODAY'S HABITS"
                                      : "${selectedCategory.toUpperCase()} HABITS"),
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
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              borderRadius: 16,
                              child: Text(
                                'No habits found for selected filters',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
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
                              onSelectDifficulty: (score) => provider
                                  .markHabitDifficulty(item.habit.id, score),
                              onIncrementQuantity: (inc) =>
                                  provider.logHabitQuantity(item.habit.id, inc),
                              onSetQuantity: (val) =>
                                  provider.markHabitDifficulty(
                                      item.habit.id, item.todayDifficulty ?? 5,
                                      valueLogged: val),
                              onAddDurationMinutes: (mins) =>
                                  provider.logHabitDuration(item.habit.id, mins),
                              onAddNote: () => _showAddNoteDialog(
                                  context, item.habit.id, item.todayNote),
                              onEdit: () =>
                                  _showEditHabitDialog(context, item.habit),
                              onArchive: () =>
                                  _archiveHabit(context, item.habit),
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

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;
  final int? badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              tooltip: tooltip,
              icon: Icon(
                icon,
                size: 19,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: onPressed,
            ),
            if (badgeCount != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
