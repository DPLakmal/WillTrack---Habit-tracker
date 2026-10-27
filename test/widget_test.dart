import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:willtrack/ui/widgets/daily_progress_card.dart';
import 'package:willtrack/ui/widgets/empty_state.dart';
import 'package:willtrack/ui/widgets/habit_dialog.dart';
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

    testWidgets('DailyProgressCard shows completion message at 100%',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyProgressCard(
              completed: 4,
              total: 4,
              progress: 1.0,
              percentage: 100,
            ),
          ),
        ),
      );

      expect(find.text('4/4 (100%)'), findsOneWidget);
      expect(find.text('🎉 All done for today! Keep it up!'), findsOneWidget);
    });

    testWidgets('HabitTile displays habit with category and fires callbacks',
        (tester) async {
      bool toggleCalled = false;
      bool tapCalled = false;

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
              habitItem: HabitItem(habit: testHabit, isCompletedToday: false),
              onTap: () => tapCalled = true,
              onToggle: () => toggleCalled = true,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Daily Swimming'), findsOneWidget);
      expect(find.text('Fitness'), findsOneWidget);

      await tester.tap(find.text('Daily Swimming'));
      expect(tapCalled, isTrue);

      await tester.tap(find.byKey(const Key('habit_toggle_button')));
      expect(toggleCalled, isTrue);
    });

    testWidgets('HabitTile shows custom symbol when completed', (tester) async {
      final testHabit = Habit(
        id: 1,
        name: 'Drink water',
        category: 'Health',
        symbol: 'water',
        colorValue: 0xFF06B6D4,
        createdAt: DateTime.now(),
        isArchived: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitTile(
              habitItem: HabitItem(habit: testHabit, isCompletedToday: true),
              onTap: () {},
              onToggle: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Drink water'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('HabitDialog validates empty inputs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HabitDialog(title: 'New Habit'),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Please enter a habit name'), findsOneWidget);
    });
  });
}
