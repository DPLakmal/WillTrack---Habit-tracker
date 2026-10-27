import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get category =>
      text().withDefault(const Constant('General'))();
  TextColumn get symbol =>
      text().withDefault(const Constant('check'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF10B981))();

  // Scheduling: 'daily', 'specific_days', 'weekly_target'
  TextColumn get scheduleType =>
      text().withDefault(const Constant('daily'))();
  // Comma-separated day numbers (1=Mon ... 7=Sun) e.g. "1,3,5"
  TextColumn get scheduleDays =>
      text().withDefault(const Constant(''))();
  // Target days per week e.g. 3
  IntColumn get weeklyTargetDays =>
      integer().withDefault(const Constant(7))();

  // Start Date
  DateTimeColumn get startDate =>
      dateTime().withDefault(currentDateAndTime)();

  // Reminder settings: "HH:mm" e.g. "08:30"
  TextColumn get reminderTime => text().nullable()();
  BoolColumn get isReminderEnabled =>
      boolean().withDefault(const Constant(false))();

  // Archiving
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id,
      onDelete: KeyAction.cascade)();
  // Formatted date string "YYYY-MM-DD"
  TextColumn get date => text().withLength(min: 10, max: 10)();
  TextColumn get status =>
      text().withDefault(const Constant('completed'))();
  TextColumn get note => text().nullable()();
  // 1-10 difficulty rating scale
  IntColumn get difficulty => integer().nullable()();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Habits, CheckIns])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(habits, habits.category);
          await m.addColumn(habits, habits.symbol);
          await m.addColumn(habits, habits.colorValue);
          await m.addColumn(checkIns, checkIns.status);
          await m.addColumn(checkIns, checkIns.note);
        }
        if (from < 3) {
          await m.addColumn(checkIns, checkIns.difficulty);
        }
        if (from < 4) {
          await m.addColumn(habits, habits.description);
          await m.addColumn(habits, habits.scheduleType);
          await m.addColumn(habits, habits.scheduleDays);
          await m.addColumn(habits, habits.weeklyTargetDays);
          await m.addColumn(habits, habits.startDate);
          await m.addColumn(habits, habits.reminderTime);
          await m.addColumn(habits, habits.isReminderEnabled);
        }
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

  Stream<List<Habit>> watchArchivedHabits() {
    return (select(habits)
          ..where((tbl) => tbl.isArchived.equals(true))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Future<List<Habit>> getActiveHabits() {
    return (select(habits)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
  }

  Future<List<Habit>> getArchivedHabits() {
    return (select(habits)
          ..where((tbl) => tbl.isArchived.equals(true))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  Future<Habit?> getHabitById(int id) {
    return (select(habits)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> addHabit(
    String name, {
    String? description,
    String category = 'General',
    String symbol = 'check',
    int colorValue = 0xFF10B981,
    String scheduleType = 'daily',
    String scheduleDays = '',
    int weeklyTargetDays = 7,
    DateTime? startDate,
    String? reminderTime,
    bool isReminderEnabled = false,
  }) {
    return into(habits).insert(
      HabitsCompanion.insert(
        name: name.trim(),
        description: Value(description?.trim()),
        category: Value(category.trim()),
        symbol: Value(symbol),
        colorValue: Value(colorValue),
        scheduleType: Value(scheduleType),
        scheduleDays: Value(scheduleDays),
        weeklyTargetDays: Value(weeklyTargetDays),
        startDate: Value(startDate ?? DateTime.now()),
        reminderTime: Value(reminderTime),
        isReminderEnabled: Value(isReminderEnabled),
      ),
    );
  }

  Future<bool> updateHabitDetails(
    int id, {
    required String name,
    String? description,
    required String category,
    required String symbol,
    required int colorValue,
    String scheduleType = 'daily',
    String scheduleDays = '',
    int weeklyTargetDays = 7,
    DateTime? startDate,
    String? reminderTime,
    bool isReminderEnabled = false,
  }) {
    return (update(habits)..where((tbl) => tbl.id.equals(id)))
        .write(
          HabitsCompanion(
            name: Value(name.trim()),
            description: Value(description?.trim()),
            category: Value(category.trim()),
            symbol: Value(symbol),
            colorValue: Value(colorValue),
            scheduleType: Value(scheduleType),
            scheduleDays: Value(scheduleDays),
            weeklyTargetDays: Value(weeklyTargetDays),
            startDate: Value(startDate ?? DateTime.now()),
            reminderTime: Value(reminderTime),
            isReminderEnabled: Value(isReminderEnabled),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<bool> archiveHabit(int id) {
    return (update(habits)..where((tbl) => tbl.id.equals(id)))
        .write(const HabitsCompanion(isArchived: Value(true)))
        .then((rows) => rows > 0);
  }

  Future<bool> unarchiveHabit(int id) {
    return (update(habits)..where((tbl) => tbl.id.equals(id)))
        .write(const HabitsCompanion(isArchived: Value(false)))
        .then((rows) => rows > 0);
  }

  Future<int> deleteHabit(int id) {
    return (delete(habits)..where((tbl) => tbl.id.equals(id))).go();
  }

  // CheckIns Queries & Streams
  Stream<List<int>> watchCompletedHabitIdsForDate(String dateStr) {
    return (select(checkIns)
          ..where((tbl) =>
              tbl.date.equals(dateStr) & tbl.status.equals('completed')))
        .watch()
        .map((rows) => rows.map((r) => r.habitId).toList());
  }

  Future<List<int>> getCompletedHabitIdsForDate(String dateStr) {
    return (select(checkIns)
          ..where((tbl) =>
              tbl.date.equals(dateStr) & tbl.status.equals('completed')))
        .get()
        .then((rows) => rows.map((r) => r.habitId).toList());
  }

  Stream<List<CheckIn>> watchCheckInsForHabit(int habitId) {
    return (select(checkIns)
          ..where((tbl) => tbl.habitId.equals(habitId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .watch();
  }

  Future<List<CheckIn>> getCheckInsForHabit(int habitId) {
    return (select(checkIns)
          ..where((tbl) => tbl.habitId.equals(habitId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .get();
  }

  Future<CheckIn?> getCheckInForDate(int habitId, String dateStr) {
    return (select(checkIns)
          ..where((tbl) =>
              tbl.habitId.equals(habitId) & tbl.date.equals(dateStr)))
        .getSingleOrNull();
  }

  Future<void> toggleCheckIn(
    int habitId,
    String dateStr, {
    int? difficulty = 5,
  }) async {
    final existing = await (select(checkIns)
          ..where((tbl) =>
              tbl.habitId.equals(habitId) & tbl.date.equals(dateStr)))
        .getSingleOrNull();

    if (existing != null) {
      await (delete(checkIns)..where((tbl) => tbl.id.equals(existing.id))).go();
    } else {
      await into(checkIns).insert(
        CheckInsCompanion.insert(
          habitId: habitId,
          date: dateStr,
          status: const Value('completed'),
          difficulty: Value(difficulty),
        ),
      );
    }
  }

  Future<void> setCheckInStatusAndNote(
    int habitId,
    String dateStr, {
    required String status,
    String? note,
    int? difficulty,
  }) async {
    final existing = await (select(checkIns)
          ..where((tbl) =>
              tbl.habitId.equals(habitId) & tbl.date.equals(dateStr)))
        .getSingleOrNull();

    if (existing != null) {
      if (status == 'none') {
        await (delete(checkIns)..where((tbl) => tbl.id.equals(existing.id))).go();
      } else {
        await (update(checkIns)..where((tbl) => tbl.id.equals(existing.id))).write(
          CheckInsCompanion(
            status: Value(status),
            note: Value(note),
            difficulty: Value(difficulty),
          ),
        );
      }
    } else {
      if (status != 'none') {
        await into(checkIns).insert(
          CheckInsCompanion.insert(
            habitId: habitId,
            date: dateStr,
            status: Value(status),
            note: Value(note),
            difficulty: Value(difficulty),
          ),
        );
      }
    }
  }
}
