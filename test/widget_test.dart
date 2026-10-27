import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:willtrack/models/achievement_model.dart';
import 'package:willtrack/models/habit_analytics.dart';
import 'package:willtrack/models/weekly_review_model.dart';
import 'package:willtrack/ui/screens/splash_screen.dart';
import 'package:willtrack/ui/widgets/achievements_sheet.dart';
import 'package:willtrack/ui/widgets/daily_progress_card.dart';
import 'package:willtrack/ui/widgets/difficulty_selector.dart';
import 'package:willtrack/ui/widgets/empty_state.dart';
import 'package:willtrack/ui/widgets/goals_sheet.dart';
import 'package:willtrack/ui/widgets/habit_analytics_section.dart';
import 'package:willtrack/ui/widgets/habit_tile.dart';
import 'package:willtrack/ui/widgets/quantity_duration_stepper.dart';
import 'package:willtrack/ui/widgets/weekly_review_sheet.dart';
import 'package:willtrack/data/database.dart';
import 'package:willtrack/providers/habit_provider.dart';

void main() {
  group('Splash Screen Tests', () {
    testWidgets('SplashScreen displays logo, title, and tagline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(autoNavigate: false),
        ),
      );

      expect(find.text('WillTrack'), findsOneWidget);
      expect(find.text('Master habits, one day at a time'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

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
        habitType: 'boolean',
        routine: 'anytime',
        createdAt: DateTime.now(),
        isArchived: false,
        scheduleType: 'daily',
        scheduleDays: '',
        weeklyTargetDays: 7,
        startDate: DateTime.now(),
        isReminderEnabled: false,
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
              onArchive: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Daily Swimming'), findsOneWidget);
      expect(find.text('Rate effort today:'), findsOneWidget);

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
        habitType: 'boolean',
        routine: 'anytime',
        createdAt: DateTime.now(),
        isArchived: false,
        scheduleType: 'daily',
        scheduleDays: '',
        weeklyTargetDays: 7,
        startDate: DateTime.now(),
        isReminderEnabled: false,
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
              onArchive: () {},
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
        habitType: 'boolean',
        routine: 'anytime',
        createdAt: DateTime.now(),
        isArchived: false,
        scheduleType: 'daily',
        scheduleDays: '',
        weeklyTargetDays: 7,
        startDate: DateTime.now(),
        isReminderEnabled: false,
      );

      final stats = HabitStats(
        currentStreak: 5,
        longestStreak: 12,
        totalCompletions: 20,
        completionRate: 0.85,
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
        weeklyPerformance: WeeklyPerformance(
          weekStart: DateTime.now(),
          weekEnd: DateTime.now(),
          days: [],
          scheduledDaysCount: 5,
          completedDaysCount: 4,
        ),
        monthlyPerformance: MonthlyPerformance(
          month: DateTime.now(),
          totalDaysInMonth: 30,
          scheduledDays: 20,
          completedDays: 17,
          completionRate: 0.85,
        ),
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
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Moderate (4-7)'), findsOneWidget);
    });

    testWidgets('QuantityStepper renders value, unit, and triggers callbacks',
        (tester) async {
      double logged = 3.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityStepper(
              currentLogged: logged,
              targetValue: 8.0,
              unit: 'glasses',
              activeColor: Colors.blue,
              onIncrement: (inc) => logged += inc,
              onSetValue: (val) => logged = val,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text(' / 8'), findsOneWidget);
      expect(find.text('glasses'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      expect(logged, 4.0);
    });

    testWidgets('AchievementsSheet renders achievement catalog with unlocked count',
        (tester) async {
      final sampleAchievements = [
        const Achievement(
          key: 'first_step',
          title: 'First Step',
          description: 'Logged your very first habit check-in.',
          icon: Icons.military_tech_rounded,
          category: 'Milestones',
          targetValue: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementsSheet(achievements: sampleAchievements),
          ),
        ),
      );

      expect(find.text('🏆 Achievements'), findsOneWidget);
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('Logged your very first habit check-in.'), findsOneWidget);
    });

    testWidgets('WeeklyReviewSheet renders weekly summary and metrics',
        (tester) async {
      final review = WeeklyReviewData(
        weekStart: DateTime(2026, 10, 26),
        weekEnd: DateTime(2026, 11, 1),
        totalScheduled: 10,
        totalCompleted: 8,
        completionRate: 0.8,
        previousWeekRate: 0.7,
        topHabits: [],
        missedHabits: [],
        totalDurationMinutes: 120.0,
        totalQuantityLogged: 16.0,
        activeHabitsCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyReviewSheet(reviewData: review),
          ),
        ),
      );

      expect(find.text('📊 Weekly Review'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('120 mins'), findsOneWidget);
      expect(find.text('16 units'), findsOneWidget);
    });

    testWidgets('GoalsSheet renders active goals list', (tester) async {
      final sampleGoals = [
        Goal(
          id: 1,
          title: 'Run 10K',
          category: 'Fitness',
          symbol: 'target',
          colorValue: 0xFF10B981,
          isArchived: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalsSheet(
              goals: sampleGoals,
              habits: [],
              onAddGoal: (title, desc, cat, color, target) {},
              onDeleteGoal: (id) {},
            ),
          ),
        ),
      );

      expect(find.text('🎯 Long-Term Goals'), findsOneWidget);
      expect(find.text('Run 10K'), findsOneWidget);
    });
  });
}
