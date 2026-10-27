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
    test('Can create a habit and read it', () async {
      final id = await db.addHabit('Read a book');
      expect(id, 1);

      final habits = await db.getActiveHabits();
      expect(habits.length, 1);
      expect(habits.first.name, 'Read a book');
    });

    test('Can update a habit name', () async {
      final id = await db.addHabit('Exercise');
      final updated = await db.updateHabitName(id, 'Morning Exercise');
      expect(updated, isTrue);

      final habits = await db.getActiveHabits();
      expect(habits.first.name, 'Morning Exercise');
    });

    test('Can delete a habit', () async {
      final id = await db.addHabit('Drink water');
      final deletedCount = await db.deleteHabit(id);
      expect(deletedCount, 1);

      final habits = await db.getActiveHabits();
      expect(habits.isEmpty, isTrue);
    });
  });

  group('Check-ins & Daily Tracking', () {
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

    test('Deleting habit cascades and deletes its check-ins', () async {
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
