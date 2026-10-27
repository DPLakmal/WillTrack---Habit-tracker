import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:willtrack/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Habits CRUD operations', () {
    test('Can create a habit with category and custom symbol', () async {
      final id = await db.addHabit(
        'Daily Swimming',
        category: 'Fitness',
        symbol: 'pool',
        colorValue: 0xFF06B6D4,
      );
      expect(id, 1);

      final habits = await db.getActiveHabits();
      expect(habits.length, 1);
      expect(habits.first.name, 'Daily Swimming');
      expect(habits.first.category, 'Fitness');
      expect(habits.first.symbol, 'pool');
      expect(habits.first.colorValue, 0xFF06B6D4);
    });

    test('Can update habit details including category and symbol', () async {
      final id = await db.addHabit('Exercise');
      final updated = await db.updateHabitDetails(
        id,
        name: 'Morning Swimming',
        category: 'Fitness',
        symbol: 'pool',
        colorValue: 0xFF06B6D4,
      );
      expect(updated, isTrue);

      final habits = await db.getActiveHabits();
      expect(habits.first.name, 'Morning Swimming');
      expect(habits.first.category, 'Fitness');
      expect(habits.first.symbol, 'pool');
    });

    test('Can delete a habit', () async {
      final id = await db.addHabit('Drink water');
      final deletedCount = await db.deleteHabit(id);
      expect(deletedCount, 1);

      final habits = await db.getActiveHabits();
      expect(habits.isEmpty, isTrue);
    });

    test('Can create habit with schedule, start date, and reminder', () async {
      final startDate = DateTime(2026, 11, 1);
      final id = await db.addHabit(
        'Read Book',
        description: 'Read 30 mins before sleep',
        category: 'Learning',
        scheduleType: 'specific_days',
        scheduleDays: '1,3,5',
        startDate: startDate,
        reminderTime: '21:30',
        isReminderEnabled: true,
      );

      final habit = await db.getHabitById(id);
      expect(habit, isNotNull);
      expect(habit!.description, 'Read 30 mins before sleep');
      expect(habit.scheduleType, 'specific_days');
      expect(habit.scheduleDays, '1,3,5');
      expect(habit.reminderTime, '21:30');
      expect(habit.isReminderEnabled, isTrue);
    });

    test('Can archive and unarchive habit without losing data', () async {
      final id = await db.addHabit('Workout', category: 'Fitness');
      await db.toggleCheckIn(id, '2026-10-27', difficulty: 7);

      // Initially active
      var active = await db.getActiveHabits();
      var archived = await db.getArchivedHabits();
      expect(active.length, 1);
      expect(archived.isEmpty, isTrue);

      // Archive
      await db.archiveHabit(id);
      active = await db.getActiveHabits();
      archived = await db.getArchivedHabits();
      expect(active.isEmpty, isTrue);
      expect(archived.length, 1);
      expect(archived.first.name, 'Workout');

      // Check-ins preserved
      final checkIns = await db.getCheckInsForHabit(id);
      expect(checkIns.length, 1);
      expect(checkIns.first.difficulty, 7);

      // Unarchive
      await db.unarchiveHabit(id);
      active = await db.getActiveHabits();
      archived = await db.getArchivedHabits();
      expect(active.length, 1);
      expect(archived.isEmpty, isTrue);
    });

    test('Can track habit with numerical target and log numerical progress', () async {
      final id = await db.addHabit(
        'Study Programming',
        category: 'Learning',
        targetValue: 45.0,
        unit: 'mins',
      );

      final habit = await db.getHabitById(id);
      expect(habit, isNotNull);
      expect(habit!.targetValue, 45.0);
      expect(habit.unit, 'mins');

      await db.toggleCheckIn(id, '2026-10-27', difficulty: 5, valueLogged: 50.0);
      final checkIn = await db.getCheckInForDate(id, '2026-10-27');
      expect(checkIn, isNotNull);
      expect(checkIn!.valueLogged, 50.0);
    });
  });

  group('Check-ins, 1-10 Difficulty Scale, & Retention Tracking', () {
    test('Can complete habit with difficulty score and undo completion', () async {
      final id = await db.addHabit('Meditate');
      const today = '2026-10-27';

      // Initially no check-in
      var completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.contains(id), isFalse);

      // Check-in (complete with difficulty 4)
      await db.toggleCheckIn(id, today, difficulty: 4);
      completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.contains(id), isTrue);

      final checkIn = await db.getCheckInForDate(id, today);
      expect(checkIn?.difficulty, 4);

      // Toggle again (undo completion)
      await db.toggleCheckIn(id, today);
      completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.contains(id), isFalse);
    });

    test('Can log day notes and 1-10 difficulty scale', () async {
      final id = await db.addHabit('Daily Swimming', category: 'Fitness', symbol: 'pool');
      const day1 = '2026-10-25';
      const day2 = '2026-10-26';

      // Record day 1: difficulty 8/10 (Challenging)
      await db.setCheckInStatusAndNote(
        id,
        day1,
        status: 'completed',
        difficulty: 8,
        note: 'Swam 2,000m high-intensity intervals',
      );

      // Record day 2: difficulty 3/10 (Light effort)
      await db.setCheckInStatusAndNote(
        id,
        day2,
        status: 'completed',
        difficulty: 3,
        note: 'Relaxed recovery swim',
      );

      final history = await db.getCheckInsForHabit(id);
      expect(history.length, 2);

      final d1Log = history.firstWhere((h) => h.date == day1);
      expect(d1Log.status, 'completed');
      expect(d1Log.difficulty, 8);
      expect(d1Log.note, 'Swam 2,000m high-intensity intervals');

      final d2Log = history.firstWhere((h) => h.date == day2);
      expect(d2Log.status, 'completed');
      expect(d2Log.difficulty, 3);
      expect(d2Log.note, 'Relaxed recovery swim');
    });

    test('Deleting habit cascades and deletes all check-ins', () async {
      final id = await db.addHabit('Study programming');
      const today = '2026-10-27';

      await db.toggleCheckIn(id, today, difficulty: 7);
      var completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.length, 1);

      await db.deleteHabit(id);

      completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.isEmpty, isTrue);
    });
  });

  group('Advanced Habit Tracking: Types, Routines, Stacks, Goals & Achievements', () {
    test('Can create Quantity and Duration habits with routines', () async {
      final qId = await db.addHabit(
        'Drink Water',
        category: 'Health',
        habitType: 'quantity',
        routine: 'morning',
        targetValue: 8.0,
        unit: 'glasses',
      );
      final dId = await db.addHabit(
        'Evening Reading',
        category: 'Learning',
        habitType: 'duration',
        routine: 'evening',
        targetValue: 30.0,
        unit: 'mins',
      );

      final qHabit = await db.getHabitById(qId);
      expect(qHabit?.habitType, 'quantity');
      expect(qHabit?.routine, 'morning');
      expect(qHabit?.targetValue, 8.0);
      expect(qHabit?.unit, 'glasses');

      final dHabit = await db.getHabitById(dId);
      expect(dHabit?.habitType, 'duration');
      expect(dHabit?.routine, 'evening');
      expect(dHabit?.targetValue, 30.0);
      expect(dHabit?.unit, 'mins');
    });

    test('Can link habits with Habit Stacking sequence', () async {
      final anchorId = await db.addHabit(
        'Morning Coffee',
        routine: 'morning',
      );
      final stackedId = await db.addHabit(
        'Read 10 Pages',
        routine: 'morning',
        stackedHabitId: anchorId,
        stackTrigger: 'After morning coffee',
      );

      final stackedHabit = await db.getHabitById(stackedId);
      expect(stackedHabit?.stackedHabitId, anchorId);
      expect(stackedHabit?.stackTrigger, 'After morning coffee');
    });

    test('Can manage Goals and link habits to Goals', () async {
      final goalId = await db.addGoal(
        'Run 10K Marathon',
        category: 'Fitness',
        description: 'Complete 10K by end of year',
      );

      final goals = await db.getActiveGoals();
      expect(goals.length, 1);
      expect(goals.first.title, 'Run 10K Marathon');

      final habitId = await db.addHabit(
        '5km Morning Run',
        category: 'Fitness',
        goalId: goalId,
      );

      final habit = await db.getHabitById(habitId);
      expect(habit?.goalId, goalId);

      await db.deleteGoal(goalId);
      final afterDelete = await db.getActiveGoals();
      expect(afterDelete.isEmpty, isTrue);
    });

    test('Can record and query Achievement unlocks', () async {
      final unlocked1 = await db.unlockBadge('first_step');
      expect(unlocked1, isTrue);

      // Duplicate unlock should return false
      final unlockedAgain = await db.unlockBadge('first_step');
      expect(unlockedAgain, isFalse);

      final badges = await db.getUnlockedBadges();
      expect(badges.length, 1);
      expect(badges.first.badgeKey, 'first_step');
    });
  });
}
