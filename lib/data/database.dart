import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:intl/intl.dart';

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

  // Habit Type: 'boolean', 'quantity', 'duration'
  TextColumn get habitType =>
      text().withDefault(const Constant('boolean'))();

  // Routine: 'anytime', 'morning', 'afternoon', 'evening'
  TextColumn get routine =>
      text().withDefault(const Constant('anytime'))();

  // Habit Stacking
  IntColumn get stackedHabitId =>
      integer().nullable().references(Habits, #id, onDelete: KeyAction.setNull)();
  TextColumn get stackTrigger => text().nullable()();

  // Connected Goal
  IntColumn get goalId =>
      integer().nullable().references(Goals, #id, onDelete: KeyAction.setNull)();

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

  // Numerical Goal (Optional e.g. 30.0 mins, 2000.0 ml, 10.0 pages)
  RealColumn get targetValue => real().nullable()();
  TextColumn get unit => text().nullable()();

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
  // Numerical value achieved (e.g. 35.0 mins)
  RealColumn get valueLogged => real().nullable()();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get category =>
      text().withDefault(const Constant('General'))();
  TextColumn get symbol =>
      text().withDefault(const Constant('target'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF10B981))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class AchievementUnlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get badgeKey => text().withLength(min: 1, max: 64)();
  DateTimeColumn get unlockedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Habits, CheckIns, Goals, AchievementUnlocks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (m, from, to) async {
        // Safe idempotent column addition helper to prevent crashes if partial migration occurred
        Future<void> addColumnIfNotExists(
          String table,
          String column,
          String definition,
        ) async {
          final res = await customSelect("PRAGMA table_info($table);").get();
          final exists = res.any((r) => r.data['name'] == column);
          if (!exists) {
            await customStatement(
              'ALTER TABLE "$table" ADD COLUMN "$column" $definition;',
            );
          }
        }

        Future<void> createTableIfNotExists(TableInfo table) async {
          try {
            await m.createTable(table);
          } catch (_) {
            // Already created or partially migrated
          }
        }

        if (from < 2) {
          await addColumnIfNotExists('habits', 'category', "TEXT NOT NULL DEFAULT 'General'");
          await addColumnIfNotExists('habits', 'symbol', "TEXT NOT NULL DEFAULT 'check'");
          await addColumnIfNotExists('habits', 'color_value', "INTEGER NOT NULL DEFAULT 4279351681");
          await addColumnIfNotExists('check_ins', 'status', "TEXT NOT NULL DEFAULT 'completed'");
          await addColumnIfNotExists('check_ins', 'note', "TEXT NULL");
        }
        if (from < 3) {
          await addColumnIfNotExists('check_ins', 'difficulty', "INTEGER NULL");
        }
        if (from < 4) {
          final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await addColumnIfNotExists('habits', 'description', "TEXT NULL");
          await addColumnIfNotExists('habits', 'schedule_type', "TEXT NOT NULL DEFAULT 'daily'");
          await addColumnIfNotExists('habits', 'schedule_days', "TEXT NOT NULL DEFAULT ''");
          await addColumnIfNotExists('habits', 'weekly_target_days', "INTEGER NOT NULL DEFAULT 7");
          await addColumnIfNotExists('habits', 'start_date', "INTEGER NOT NULL DEFAULT $nowEpoch");
          await addColumnIfNotExists('habits', 'reminder_time', "TEXT NULL");
          await addColumnIfNotExists('habits', 'is_reminder_enabled', "INTEGER NOT NULL DEFAULT 0");
        }
        if (from < 5) {
          await addColumnIfNotExists('habits', 'target_value', "REAL NULL");
          await addColumnIfNotExists('habits', 'unit', "TEXT NULL");
          await addColumnIfNotExists('check_ins', 'value_logged', "REAL NULL");
        }
        if (from < 6) {
          await createTableIfNotExists(goals);
          await createTableIfNotExists(achievementUnlocks);
          await addColumnIfNotExists('habits', 'habit_type', "TEXT NOT NULL DEFAULT 'boolean'");
          await addColumnIfNotExists('habits', 'routine', "TEXT NOT NULL DEFAULT 'anytime'");
          await addColumnIfNotExists('habits', 'stacked_habit_id', "INTEGER NULL");
          await addColumnIfNotExists('habits', 'stack_trigger', "TEXT NULL");
          await addColumnIfNotExists('habits', 'goal_id', "INTEGER NULL");
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
    String habitType = 'boolean',
    String routine = 'anytime',
    int? stackedHabitId,
    String? stackTrigger,
    int? goalId,
    String scheduleType = 'daily',
    String scheduleDays = '',
    int weeklyTargetDays = 7,
    DateTime? startDate,
    double? targetValue,
    String? unit,
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
        habitType: Value(habitType),
        routine: Value(routine),
        stackedHabitId: Value(stackedHabitId),
        stackTrigger: Value(stackTrigger?.trim()),
        goalId: Value(goalId),
        scheduleType: Value(scheduleType),
        scheduleDays: Value(scheduleDays),
        weeklyTargetDays: Value(weeklyTargetDays),
        startDate: Value(startDate ?? DateTime.now()),
        targetValue: Value(targetValue),
        unit: Value(unit?.trim()),
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
    String habitType = 'boolean',
    String routine = 'anytime',
    int? stackedHabitId,
    String? stackTrigger,
    int? goalId,
    String scheduleType = 'daily',
    String scheduleDays = '',
    int weeklyTargetDays = 7,
    DateTime? startDate,
    double? targetValue,
    String? unit,
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
            habitType: Value(habitType),
            routine: Value(routine),
            stackedHabitId: Value(stackedHabitId),
            stackTrigger: Value(stackTrigger?.trim()),
            goalId: Value(goalId),
            scheduleType: Value(scheduleType),
            scheduleDays: Value(scheduleDays),
            weeklyTargetDays: Value(weeklyTargetDays),
            startDate: Value(startDate ?? DateTime.now()),
            targetValue: Value(targetValue),
            unit: Value(unit?.trim()),
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
    double? valueLogged,
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
          valueLogged: Value(valueLogged),
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
    double? valueLogged,
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
            valueLogged: Value(valueLogged),
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
            valueLogged: Value(valueLogged),
          ),
        );
      }
    }
  }

  // Goals Queries & Streams
  Stream<List<Goal>> watchGoals() {
    return (select(goals)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .watch();
  }

  Future<List<Goal>> getActiveGoals() {
    return (select(goals)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
  }

  Future<Goal?> getGoalById(int id) {
    return (select(goals)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> addGoal(
    String title, {
    String? description,
    String category = 'General',
    String symbol = 'target',
    int colorValue = 0xFF10B981,
    DateTime? targetDate,
  }) {
    return into(goals).insert(
      GoalsCompanion.insert(
        title: title.trim(),
        description: Value(description?.trim()),
        category: Value(category.trim()),
        symbol: Value(symbol),
        colorValue: Value(colorValue),
        targetDate: Value(targetDate),
      ),
    );
  }

  Future<bool> updateGoalDetails(
    int id, {
    required String title,
    String? description,
    required String category,
    required String symbol,
    required int colorValue,
    DateTime? targetDate,
  }) {
    return (update(goals)..where((tbl) => tbl.id.equals(id)))
        .write(
          GoalsCompanion(
            title: Value(title.trim()),
            description: Value(description?.trim()),
            category: Value(category.trim()),
            symbol: Value(symbol),
            colorValue: Value(colorValue),
            targetDate: Value(targetDate),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<bool> archiveGoal(int id) {
    return (update(goals)..where((tbl) => tbl.id.equals(id)))
        .write(const GoalsCompanion(isArchived: Value(true)))
        .then((rows) => rows > 0);
  }

  Future<int> deleteGoal(int id) {
    return (delete(goals)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Achievements Queries & Streams
  Stream<List<AchievementUnlock>> watchUnlockedBadges() {
    return (select(achievementUnlocks)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.unlockedAt)]))
        .watch();
  }

  Future<List<AchievementUnlock>> getUnlockedBadges() {
    return (select(achievementUnlocks)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.unlockedAt)]))
        .get();
  }

  Future<bool> unlockBadge(String badgeKey) async {
    final existing = await (select(achievementUnlocks)
          ..where((tbl) => tbl.badgeKey.equals(badgeKey)))
        .getSingleOrNull();
    if (existing != null) return false;

    await into(achievementUnlocks).insert(
      AchievementUnlocksCompanion.insert(badgeKey: badgeKey),
    );
    return true;
  }

  // Pre-seed default data if database is brand new / freshly installed
  Future<void> seedInitialDataIfEmpty() async {
    final existing = await (select(habits)..limit(1)).get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    final day2 = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 2)));
    final day3 = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3)));
    final day4 = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 4)));

    // 1. Read a book
    final h1 = await addHabit(
      'Read a book',
      description: 'Read 20 pages every evening',
      category: 'Learning',
      symbol: 'book',
      colorValue: 0xFF3B82F6,
      habitType: 'quantity',
      routine: 'evening',
      targetValue: 20,
      unit: 'pages',
    );
    await setCheckInStatusAndNote(h1, day4, status: 'completed', difficulty: 4, valueLogged: 20);
    await setCheckInStatusAndNote(h1, day3, status: 'completed', difficulty: 5, valueLogged: 22);
    await setCheckInStatusAndNote(h1, day2, status: 'completed', difficulty: 4, valueLogged: 25);
    await setCheckInStatusAndNote(h1, yesterday, status: 'completed', difficulty: 3, valueLogged: 20);
    await setCheckInStatusAndNote(h1, today, status: 'completed', difficulty: 4, valueLogged: 20);

    // 2. Exercise
    final h2 = await addHabit(
      'Exercise',
      description: 'Morning workout or running',
      category: 'Fitness',
      symbol: 'fitness',
      colorValue: 0xFF10B981,
      habitType: 'duration',
      routine: 'morning',
      targetValue: 30,
      unit: 'mins',
    );
    await setCheckInStatusAndNote(h2, day3, status: 'completed', difficulty: 7, valueLogged: 30);
    await setCheckInStatusAndNote(h2, day2, status: 'completed', difficulty: 6, valueLogged: 35);
    await setCheckInStatusAndNote(h2, yesterday, status: 'completed', difficulty: 5, valueLogged: 30);
    await setCheckInStatusAndNote(h2, today, status: 'completed', difficulty: 6, valueLogged: 30);

    // 3. Drink water
    final h3 = await addHabit(
      'Drink water',
      description: 'Stay hydrated throughout the day',
      category: 'Health',
      symbol: 'water',
      colorValue: 0xFF06B6D4,
      habitType: 'quantity',
      routine: 'anytime',
      targetValue: 8,
      unit: 'glasses',
    );
    await setCheckInStatusAndNote(h3, day4, status: 'completed', difficulty: 2, valueLogged: 8);
    await setCheckInStatusAndNote(h3, day3, status: 'completed', difficulty: 3, valueLogged: 8);
    await setCheckInStatusAndNote(h3, day2, status: 'completed', difficulty: 2, valueLogged: 9);
    await setCheckInStatusAndNote(h3, yesterday, status: 'completed', difficulty: 2, valueLogged: 8);
    await setCheckInStatusAndNote(h3, today, status: 'completed', difficulty: 2, valueLogged: 6);

    // 4. Study programming
    final h4 = await addHabit(
      'Study programming',
      description: 'Flutter & Dart coding session',
      category: 'Learning',
      symbol: 'code',
      colorValue: 0xFF8B5CF6,
      habitType: 'duration',
      routine: 'afternoon',
      targetValue: 45,
      unit: 'mins',
    );
    await setCheckInStatusAndNote(h4, day3, status: 'completed', difficulty: 6, valueLogged: 45);
    await setCheckInStatusAndNote(h4, day2, status: 'completed', difficulty: 7, valueLogged: 50);
    await setCheckInStatusAndNote(h4, yesterday, status: 'completed', difficulty: 5, valueLogged: 45);

    // 5. Sleep before 10 PM
    final h5 = await addHabit(
      'Sleep before 10 PM',
      description: 'Maintain healthy sleep schedule',
      category: 'Health',
      symbol: 'bed',
      colorValue: 0xFFEC4899,
      habitType: 'boolean',
      routine: 'evening',
    );
    await setCheckInStatusAndNote(h5, day3, status: 'completed', difficulty: 4);
    await setCheckInStatusAndNote(h5, yesterday, status: 'completed', difficulty: 3);

    // Sample Goal
    final gId = await addGoal(
      'Read 20 Books This Year',
      category: 'Learning',
      description: 'Build consistent reading habit in 2026',
    );
    await (update(habits)..where((tbl) => tbl.id.equals(h1))).write(
      HabitsCompanion(goalId: Value(gId)),
    );
  }
}
