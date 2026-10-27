import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
}

class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id,
      onDelete: KeyAction.cascade)();
  // Formatted date string "YYYY-MM-DD"
  TextColumn get date => text().withLength(min: 10, max: 10)();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Habits, CheckIns])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'willtrack_db');
  }

  // Habits Queries & Streams
  Stream<List<Habit>> watchActiveHabits() {
    return (select(habits)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .watch();
  }

  Future<List<Habit>> getActiveHabits() {
    return (select(habits)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
  }

  Future<int> addHabit(String name) {
    return into(habits).insert(
      HabitsCompanion.insert(
        name: name.trim(),
      ),
    );
  }

  Future<bool> updateHabitName(int id, String newName) {
    return (update(habits)..where((tbl) => tbl.id.equals(id)))
        .write(HabitsCompanion(name: Value(newName.trim())))
        .then((rows) => rows > 0);
  }

  Future<int> deleteHabit(int id) {
    return (delete(habits)..where((tbl) => tbl.id.equals(id))).go();
  }

  // CheckIns Queries & Streams
  Stream<List<int>> watchCompletedHabitIdsForDate(String dateStr) {
    return (select(checkIns)..where((tbl) => tbl.date.equals(dateStr)))
        .watch()
        .map((rows) => rows.map((r) => r.habitId).toList());
  }

  Future<List<int>> getCompletedHabitIdsForDate(String dateStr) {
    return (select(checkIns)..where((tbl) => tbl.date.equals(dateStr)))
        .get()
        .then((rows) => rows.map((r) => r.habitId).toList());
  }

  Future<void> toggleCheckIn(int habitId, String dateStr) async {
    final existing = await (select(checkIns)
          ..where((tbl) =>
              tbl.habitId.equals(habitId) & tbl.date.equals(dateStr)))
        .getSingleOrNull();

    if (existing != null) {
      // Undo completion
      await (delete(checkIns)..where((tbl) => tbl.id.equals(existing.id))).go();
    } else {
      // Complete habit
      await into(checkIns).insert(
        CheckInsCompanion.insert(
          habitId: habitId,
          date: dateStr,
        ),
      );
    }
  }
}
