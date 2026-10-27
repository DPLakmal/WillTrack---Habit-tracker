import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:willtrack/ui/widgets/daily_progress_card.dart';
import 'package:willtrack/ui/widgets/difficulty_selector.dart';
import 'package:willtrack/ui/widgets/empty_state.dart';
import 'package:willtrack/ui/widgets/habit_analytics_section.dart';
import 'package:willtrack/ui/widgets/habit_tile.dart';
import 'package:willtrack/data/database.dart';
import 'package:willtrack/providers/habit_provider.dart';

void main() {
  group('UI Widgets Tests', () {
    testWidgets('EmptyStateWidget renders CTA button and texts', (tester) async {
      bool addCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              onAddHabit: () {
                addCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No habits yet'), findsOneWidget);
      expect(find.text('Add your first habit'), findsOneWidget);

      await tester.tap(find.text('Add your first habit'));
      expect(addCalled, isTrue);
    });

    testWidgets('DailyProgressCard displays completed/total and percentage',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyProgressCard(
              completed: 3,
              total: 5,
              progress: 0.6,
              percentage: 60,
            ),
          ),
        ),
      );

      expect(find.text("Today's Progress"), findsOneWidget);
      expect(find.text('3/5 (60%)'), findsOneWidget);
      expect(find.text('2 remaining habits'), findsOneWidget);
    });

    testWidgets('DifficultySelector renders 1-10 scores and triggers callback',
        (tester) async {
      int selected = 5;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: DifficultySelector(
                  selectedDifficulty: selected,
                  onChanged: (val) {
                    setState(() {
                      selected = val;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('5 / 10'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      await tester.tap(find.text('8'));
      await tester.pump();

      expect(selected, 8);
      expect(find.text('8 / 10'), findsOneWidget);
      expect(find.text('Challenging (Pushed limits)'), findsOneWidget);
    });

    testWidgets('HabitTile allows direct 1-10 difficulty selection inline',
        (tester) async {
      int? selectedDiff;

      final testHabit = Habit(
        id: 1,
        name: 'Daily Swimming',
        category: 'Fitness',
        symbol: 'pool',
        colorValue: 0xFF06B6D4,
        createdAt: DateTime.now(),
        isArchived: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitTile(
              habitItem: HabitItem(
                habit: testHabit,
                isCompletedToday: false,
              ),
              onTap: () {},
              onToggle: () {},
              onSelectDifficulty: (score) => selectedDiff = score,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Daily Swimming'), findsOneWidget);
      expect(find.text('Rate effort today:'), findsOneWidget);

      // Tap 4 directly on the habit row
      final diff4Button = find.byKey(const Key('diff_button_1_4'));
      expect(diff4Button, findsOneWidget);

      await tester.tap(diff4Button);
      expect(selectedDiff, 4);
    });

    testWidgets('HabitTile displays selected difficulty badge when marked',
        (tester) async {
      final testHabit = Habit(
        id: 1,
        name: 'Daily Swimming',
        category: 'Fitness',
        symbol: 'pool',
        colorValue: 0xFF06B6D4,
        createdAt: DateTime.now(),
        isArchived: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitTile(
              habitItem: HabitItem(
                habit: testHabit,
                isCompletedToday: true,
                todayDifficulty: 4,
              ),
              onTap: () {},
              onToggle: () {},
              onSelectDifficulty: (_) {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Diff: 4/10'), findsOneWidget);
      expect(find.text('Light Effort (Smooth)'), findsOneWidget);
    });

    testWidgets('HabitAnalyticsSection renders streaks, average difficulty and distribution',
        (tester) async {
      final testHabit = Habit(
        id: 1,
        name: 'Daily Swimming',
        category: 'Fitness',
        symbol: 'pool',
        colorValue: 0xFF06B6D4,
        createdAt: DateTime.now(),
        isArchived: false,
      );

      final stats = HabitStats(
        currentStreak: 5,
        longestStreak: 12,
        totalCompletions: 20,
        averageDifficulty: 6.5,
        trendMessage: 'Getting easier! Habit mastery improving 🚀',
        difficultyDistribution: {
          'Easy (1-3)': 4,
          'Moderate (4-7)': 12,
          'Hard (8-10)': 4,
        },
        recentSessions: [
          CheckIn(
            id: 1,
            habitId: 1,
            date: '2026-10-27',
            status: 'completed',
            note: '1000m swim',
            difficulty: 6,
            completedAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HabitAnalyticsSection(
                habit: testHabit,
                stats: stats,
              ),
            ),
          ),
        ),
      );

      expect(find.text('5 Days'), findsOneWidget);
      expect(find.text('12 Days'), findsOneWidget);
      expect(find.text('6.5 / 10'), findsOneWidget);
      expect(find.text('Getting easier! Habit mastery improving 🚀'), findsOneWidget);
      expect(find.text('12 sessions'), findsOneWidget);
    });
  });
}
