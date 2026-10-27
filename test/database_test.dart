import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:willtrack/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory database for testing
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
  });

  group('Check-ins, Notes, & Calendar Retention Tracking', () {
    test('Can complete habit and undo completion', () async {
      final id = await db.addHabit('Meditate');
      const today = '2026-10-27';

      // Initially no check-in
      var completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.contains(id), isFalse);

      // Check-in (complete)
      await db.toggleCheckIn(id, today);
      completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.contains(id), isTrue);

      // Toggle again (undo completion)
      await db.toggleCheckIn(id, today);
      completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.contains(id), isFalse);
    });

    test('Can log day notes and check-in statuses (e.g. for retention)', () async {
      final id = await db.addHabit('Daily Swimming', category: 'Fitness', symbol: 'pool');
      const day1 = '2026-10-25';
      const day2 = '2026-10-26';

      // Record day 1 with swimming laps note
      await db.setCheckInStatusAndNote(
        id,
        day1,
        status: 'completed',
        note: 'Swam 1,500m freestyle',
      );

      // Record day 2 as skipped
      await db.setCheckInStatusAndNote(
        id,
        day2,
        status: 'skipped',
        note: 'Pool maintenance',
      );

      final history = await db.getCheckInsForHabit(id);
      expect(history.length, 2);

      final d1Log = history.firstWhere((h) => h.date == day1);
      expect(d1Log.status, 'completed');
      expect(d1Log.note, 'Swam 1,500m freestyle');

      final d2Log = history.firstWhere((h) => h.date == day2);
      expect(d2Log.status, 'skipped');
      expect(d2Log.note, 'Pool maintenance');
    });

    test('Deleting habit cascades and deletes all history logs', () async {
      final id = await db.addHabit('Study programming');
      const today = '2026-10-27';

      await db.toggleCheckIn(id, today);
      var completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.length, 1);

      // Delete habit
      await db.deleteHabit(id);

      // Check-ins for this habit should no longer exist
      completedIds = await db.getCompletedHabitIdsForDate(today);
      expect(completedIds.isEmpty, isTrue);
    });
  });
}
