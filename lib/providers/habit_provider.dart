import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../models/achievement_model.dart';
import '../models/habit_analytics.dart';
import '../models/weekly_review_model.dart';
import '../services/notification_service.dart';

class HabitItem {
  final Habit habit;
  final bool isCompletedToday;
  final int? todayDifficulty;
  final String? todayNote;
  final double? todayValueLogged;
  final bool isDueToday;
  final String? stackedHabitName;
  final bool isStackAnchorCompleted;
  final String? linkedGoalTitle;

  HabitItem({
    required this.habit,
    required this.isCompletedToday,
    this.todayDifficulty,
    this.todayNote,
    this.todayValueLogged,
    this.isDueToday = true,
    this.stackedHabitName,
    this.isStackAnchorCompleted = false,
    this.linkedGoalTitle,
  });

  String get habitType => habit.habitType;
  String get routine => habit.routine;
  bool get isBoolean => habit.habitType == 'boolean';
  bool get isQuantity => habit.habitType == 'quantity';
  bool get isDuration => habit.habitType == 'duration';
  bool get isStacked =>
      habit.stackedHabitId != null ||
      (habit.stackTrigger != null && habit.stackTrigger!.isNotEmpty);
}

class HabitStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final double completionRate;
  final double averageDifficulty;
  final String trendMessage;
  final Map<String, int> difficultyDistribution;
  final List<CheckIn> recentSessions;
  final WeeklyPerformance weeklyPerformance;
  final MonthlyPerformance monthlyPerformance;
  final NumericalGoalProgress? numericalProgress;

  HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.completionRate,
    required this.averageDifficulty,
    required this.trendMessage,
    required this.difficultyDistribution,
    required this.recentSessions,
    required this.weeklyPerformance,
    required this.monthlyPerformance,
    this.numericalProgress,
  });
}

class HabitProvider extends ChangeNotifier {
  final AppDatabase database;
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedCategory = 'All';
  String _selectedRoutine = 'All';
  bool _groupByRoutine = false;
  bool _areNotificationsEnabled = true;

  List<Habit> _habits = [];
  List<Habit> _archivedHabits = [];
  List<Goal> _goals = [];
  List<AchievementUnlock> _unlockedBadges = [];
  Map<int, CheckIn> _todayCheckInsMap = {};

  String? _latestUnlockedAchievement;

  StreamSubscription? _habitsSubscription;
  StreamSubscription? _archivedSubscription;
  StreamSubscription? _goalsSubscription;
  StreamSubscription? _achievementsSubscription;
  StreamSubscription? _checkInsSubscription;

  HabitProvider({required this.database}) {
    _initStreams();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get selectedCategory => _selectedCategory;
  String get selectedRoutine => _selectedRoutine;
  bool get groupByRoutine => _groupByRoutine;
  bool get areNotificationsEnabled => _areNotificationsEnabled;
  List<Habit> get archivedHabits => _archivedHabits;
  List<Goal> get goals => _goals;
  List<AchievementUnlock> get unlockedBadges => _unlockedBadges;
  int get unlockedAchievementsCount => _unlockedBadges.length;
  String? get latestUnlockedAchievement => _latestUnlockedAchievement;

  void clearLatestAchievement() {
    _latestUnlockedAchievement = null;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void toggleGroupByRoutine() {
    _groupByRoutine = !_groupByRoutine;
    notifyListeners();
  }

  void toggleGlobalNotifications(bool enabled) {
    _areNotificationsEnabled = enabled;
    if (!enabled) {
      NotificationService().cancelAll();
    } else {
      for (final h in _habits) {
        if (h.isReminderEnabled) {
          NotificationService().scheduleHabitReminder(h);
        }
      }
    }
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedRoutine(String routine) {
    _selectedRoutine = routine;
    notifyListeners();
  }

  String get todayString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _initStreams() {
    _habitsSubscription = database.watchActiveHabits().listen((habits) {
      _habits = habits;
      _checkAchievements();
      notifyListeners();
    });

    _archivedSubscription = database.watchArchivedHabits().listen((archived) {
      _archivedHabits = archived;
      notifyListeners();
    });

    _goalsSubscription = database.watchGoals().listen((goals) {
      _goals = goals;
      notifyListeners();
    });

    _achievementsSubscription = database.watchUnlockedBadges().listen((badges) {
      _unlockedBadges = badges;
      notifyListeners();
    });

    _checkInsSubscription =
        (database.select(database.checkIns)..where((tbl) => tbl.date.equals(todayString)))
            .watch()
            .listen((checkIns) {
      _todayCheckInsMap = {
        for (var c in checkIns)
          if (c.status == 'completed') c.habitId: c,
      };
      _checkAchievements();
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    _habits = await database.getActiveHabits();
    _archivedHabits = await database.getArchivedHabits();
    _goals = await database.getActiveGoals();
    _unlockedBadges = await database.getUnlockedBadges();
    final todayList = await (database.select(database.checkIns)
          ..where((tbl) => tbl.date.equals(todayString)))
        .get();
    _todayCheckInsMap = {
      for (var c in todayList)
        if (c.status == 'completed') c.habitId: c,
    };
    await _checkAchievements();
    notifyListeners();
  }

  List<String> get categories {
    final defaultCategories = [
      'All',
      'Fitness',
      'Learning',
      'Health',
      'Productivity',
      'General',
      'Mindfulness'
    ];
    final existingFromHabits = _habits.map((h) => h.category).toSet();
    final combined = {...defaultCategories, ...existingFromHabits}.toList();
    return combined;
  }

  List<String> get routines => ['All', 'Morning', 'Afternoon', 'Evening', 'Anytime'];

  List<Achievement> get achievements {
    final unlockedMap = {
      for (var u in _unlockedBadges) u.badgeKey: u.unlockedAt,
    };
    return AchievementCatalog.all.map((catalogItem) {
      final unlockedAt = unlockedMap[catalogItem.key];
      return catalogItem.copyWith(unlockedAt: unlockedAt);
    }).toList();
  }

  bool isHabitDueOn(Habit habit, DateTime date) {
    // 1. Start date check
    final startDay = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
    final checkDay = DateTime(date.year, date.month, date.day);
    if (checkDay.isBefore(startDay)) return false;

    // 2. Schedule type check
    if (habit.scheduleType == 'daily') return true;

    if (habit.scheduleType == 'specific_days') {
      final weekday = date.weekday; // 1=Mon ... 7=Sun
      final days = habit.scheduleDays
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toSet();
      return days.isEmpty || days.contains(weekday);
    }

    if (habit.scheduleType == 'weekly_target') {
      return true;
    }

    return true;
  }

  List<HabitItem> get allHabitItems {
    final now = DateTime.now();
    final habitMap = {for (var h in _habits) h.id: h};
    final goalMap = {for (var g in _goals) g.id: g};

    return _habits.map((habit) {
      final checkIn = _todayCheckInsMap[habit.id];
      final isDue = isHabitDueOn(habit, now);

      String? parentName;
      bool isParentDone = false;
      if (habit.stackedHabitId != null) {
        parentName = habitMap[habit.stackedHabitId]?.name;
        isParentDone = _todayCheckInsMap.containsKey(habit.stackedHabitId);
      }

      String? goalTitle;
      if (habit.goalId != null) {
        goalTitle = goalMap[habit.goalId]?.title;
      }

      return HabitItem(
        habit: habit,
        isCompletedToday: checkIn != null,
        todayDifficulty: checkIn?.difficulty,
        todayNote: checkIn?.note,
        todayValueLogged: checkIn?.valueLogged,
        isDueToday: isDue,
        stackedHabitName: parentName,
        isStackAnchorCompleted: isParentDone,
        linkedGoalTitle: goalTitle,
      );
    }).toList();
  }

  /// Habits filtered by category and routine and due today
  List<HabitItem> get habitItems {
    final all = allHabitItems;
    var filtered = all;

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((item) =>
              item.habit.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    if (_selectedRoutine != 'All') {
      filtered = filtered
          .where((item) =>
              item.habit.routine.toLowerCase() == _selectedRoutine.toLowerCase())
          .toList();
    }

    return filtered;
  }

  int get totalCount => allHabitItems.where((h) => h.isDueToday).length;

  int get completedCount => allHabitItems
      .where((h) => h.isDueToday && h.isCompletedToday)
      .length;

  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  int get progressPercentInt {
    return (progressPercentage * 100).round();
  }

  Future<void> addHabit(
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
  }) async {
    if (name.trim().isEmpty) return;
    final id = await database.addHabit(
      name,
      description: description,
      category: category,
      symbol: symbol,
      colorValue: colorValue,
      habitType: habitType,
      routine: routine,
      stackedHabitId: stackedHabitId,
      stackTrigger: stackTrigger,
      goalId: goalId,
      scheduleType: scheduleType,
      scheduleDays: scheduleDays,
      weeklyTargetDays: weeklyTargetDays,
      startDate: startDate,
      targetValue: targetValue,
      unit: unit,
      reminderTime: reminderTime,
      isReminderEnabled: isReminderEnabled,
    );

    if (isReminderEnabled && _areNotificationsEnabled) {
      final habit = await database.getHabitById(id);
      if (habit != null) {
        NotificationService().scheduleHabitReminder(habit);
      }
    }
    await refresh();
  }

  Future<void> editHabit(
    int id,
    String newName, {
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
  }) async {
    if (newName.trim().isEmpty) return;
    await database.updateHabitDetails(
      id,
      name: newName,
      description: description,
      category: category,
      symbol: symbol,
      colorValue: colorValue,
      habitType: habitType,
      routine: routine,
      stackedHabitId: stackedHabitId,
      stackTrigger: stackTrigger,
      goalId: goalId,
      scheduleType: scheduleType,
      scheduleDays: scheduleDays,
      weeklyTargetDays: weeklyTargetDays,
      startDate: startDate,
      targetValue: targetValue,
      unit: unit,
      reminderTime: reminderTime,
      isReminderEnabled: isReminderEnabled,
    );

    final habit = await database.getHabitById(id);
    if (habit != null) {
      if (isReminderEnabled && _areNotificationsEnabled) {
        NotificationService().scheduleHabitReminder(habit);
      } else {
        NotificationService().cancelHabitReminder(id);
      }
    }
    await refresh();
  }

  Future<void> archiveHabit(int id) async {
    await database.archiveHabit(id);
    NotificationService().cancelHabitReminder(id);
    await refresh();
  }

  Future<void> unarchiveHabit(int id) async {
    await database.unarchiveHabit(id);
    final habit = await database.getHabitById(id);
    if (habit != null && habit.isReminderEnabled && _areNotificationsEnabled) {
      NotificationService().scheduleHabitReminder(habit);
    }
    await refresh();
  }

  Future<void> deleteHabit(int id) async {
    await database.deleteHabit(id);
    NotificationService().cancelHabitReminder(id);
    await refresh();
  }

  Future<void> toggleHabitCompletion(
    int habitId, {
    int? difficulty = 5,
    double? valueLogged,
  }) async {
    await database.toggleCheckIn(
      habitId,
      todayString,
      difficulty: difficulty,
      valueLogged: valueLogged,
    );
    await refresh();
  }

  Future<void> logHabitQuantity(int habitId, double increment) async {
    final existing = await database.getCheckInForDate(habitId, todayString);
    final currentVal = existing?.valueLogged ?? 0.0;
    final newVal = (currentVal + increment).clamp(0.0, 999999.0);

    if (newVal == 0.0 && existing != null) {
      await database.setCheckInStatusAndNote(
        habitId,
        todayString,
        status: 'none',
      );
    } else {
      await database.setCheckInStatusAndNote(
        habitId,
        todayString,
        status: 'completed',
        difficulty: existing?.difficulty ?? 5,
        note: existing?.note,
        valueLogged: newVal,
      );
    }
    await refresh();
  }

  Future<void> logHabitDuration(int habitId, double minutes) async {
    final existing = await database.getCheckInForDate(habitId, todayString);
    final currentVal = existing?.valueLogged ?? 0.0;
    final newVal = (currentVal + minutes).clamp(0.0, 1440.0);

    await database.setCheckInStatusAndNote(
      habitId,
      todayString,
      status: 'completed',
      difficulty: existing?.difficulty ?? 5,
      note: existing?.note,
      valueLogged: newVal,
    );
    await refresh();
  }

  Future<void> attachNoteToCheckIn(
    int habitId,
    String dateStr,
    String note,
  ) async {
    final existing = await database.getCheckInForDate(habitId, dateStr);
    await database.setCheckInStatusAndNote(
      habitId,
      dateStr,
      status: existing?.status ?? 'completed',
      difficulty: existing?.difficulty ?? 5,
      note: note.trim().isEmpty ? null : note.trim(),
      valueLogged: existing?.valueLogged,
    );
    await refresh();
  }

  Future<void> markHabitDifficulty(
    int habitId,
    int difficulty, {
    double? valueLogged,
  }) async {
    final existing = await database.getCheckInForDate(habitId, todayString);
    await database.setCheckInStatusAndNote(
      habitId,
      todayString,
      status: 'completed',
      difficulty: difficulty,
      note: existing?.note,
      valueLogged: valueLogged ?? existing?.valueLogged,
    );
    await refresh();
  }

  Future<void> completeHabitWithDetails(
    int habitId, {
    required int difficulty,
    String? note,
    double? valueLogged,
  }) async {
    await database.setCheckInStatusAndNote(
      habitId,
      todayString,
      status: 'completed',
      difficulty: difficulty,
      note: note,
      valueLogged: valueLogged,
    );
    await refresh();
  }

  Future<CheckIn?> getTodayCheckIn(int habitId) {
    return database.getCheckInForDate(habitId, todayString);
  }

  Stream<List<CheckIn>> watchHabitHistory(int habitId) {
    return database.watchCheckInsForHabit(habitId);
  }

  Future<void> updateDayLog(
    int habitId,
    String dateStr, {
    required String status,
    String? note,
    int? difficulty,
    double? valueLogged,
  }) async {
    await database.setCheckInStatusAndNote(
      habitId,
      dateStr,
      status: status,
      note: note,
      difficulty: difficulty,
      valueLogged: valueLogged,
    );
    await refresh();
  }

  // Goals CRUD
  Future<int> addGoal(
    String title, {
    String? description,
    String category = 'General',
    String symbol = 'target',
    int colorValue = 0xFF10B981,
    DateTime? targetDate,
  }) async {
    final id = await database.addGoal(
      title,
      description: description,
      category: category,
      symbol: symbol,
      colorValue: colorValue,
      targetDate: targetDate,
    );
    await refresh();
    return id;
  }

  Future<void> editGoal(
    int id, {
    required String title,
    String? description,
    required String category,
    required String symbol,
    required int colorValue,
    DateTime? targetDate,
  }) async {
    await database.updateGoalDetails(
      id,
      title: title,
      description: description,
      category: category,
      symbol: symbol,
      colorValue: colorValue,
      targetDate: targetDate,
    );
    await refresh();
  }

  Future<void> archiveGoal(int id) async {
    await database.archiveGoal(id);
    await refresh();
  }

  Future<void> deleteGoal(int id) async {
    await database.deleteGoal(id);
    await refresh();
  }

  // Achievements Evaluator
  Future<void> _checkAchievements() async {
    final allCheckIns = await database.select(database.checkIns).get();
    final completedCheckIns = allCheckIns.where((c) => c.status == 'completed').toList();

    Future<void> tryUnlock(String key) async {
      final unlocked = await database.unlockBadge(key);
      if (unlocked) {
        final item = AchievementCatalog.all.firstWhere(
          (a) => a.key == key,
          orElse: () => AchievementCatalog.all.first,
        );
        _latestUnlockedAchievement = item.title;
      }
    }

    if (completedCheckIns.isNotEmpty) {
      await tryUnlock('first_step');
    }

    if (completedCheckIns.length >= 100) {
      await tryUnlock('century_100');
    }

    // Check goal connection
    final hasGoalAttached = _habits.any((h) => h.goalId != null);
    if (hasGoalAttached) {
      await tryUnlock('goal_setter');
    }

    // Check perfect day
    if (totalCount > 0 && completedCount == totalCount) {
      await tryUnlock('perfect_day');
    }

    // Check streaks and target completions
    int maxStreakFound = 0;
    int targetHitsCount = 0;

    for (final habit in _habits) {
      final habitHistory = completedCheckIns.where((c) => c.habitId == habit.id).toList();
      final stats = computeHabitStats(habit, habitHistory);
      if (stats.longestStreak > maxStreakFound) {
        maxStreakFound = stats.longestStreak;
      }
      if (stats.currentStreak > maxStreakFound) {
        maxStreakFound = stats.currentStreak;
      }

      if (habit.targetValue != null && habit.targetValue! > 0) {
        final hits = habitHistory.where((c) => (c.valueLogged ?? 0) >= habit.targetValue!).length;
        targetHitsCount += hits;
      }

      // Check stacking completion
      if (habit.stackedHabitId != null) {
        final anchorCheck = _todayCheckInsMap.containsKey(habit.stackedHabitId);
        final thisCheck = _todayCheckInsMap.containsKey(habit.id);
        if (anchorCheck && thisCheck) {
          await tryUnlock('habit_stacker');
        }
      }

      // Check early bird / night owl
      final todayCheck = _todayCheckInsMap[habit.id];
      if (todayCheck != null) {
        final completedHour = todayCheck.completedAt.hour;
        if (habit.routine == 'morning' && completedHour < 9) {
          await tryUnlock('early_bird');
        }
        if (habit.routine == 'evening' && completedHour >= 20) {
          await tryUnlock('night_owl');
        }
      }
    }

    if (maxStreakFound >= 3) await tryUnlock('streak_3');
    if (maxStreakFound >= 7) await tryUnlock('streak_7');
    if (maxStreakFound >= 30) await tryUnlock('streak_30');
    if (targetHitsCount >= 5) await tryUnlock('target_crusher');
  }

  WeeklyPerformance computeWeeklyPerformance(
    Habit habit,
    List<CheckIn> history, [
    DateTime? referenceDate,
  ]) {
    final ref = referenceDate ?? DateTime.now();
    final monday = DateTime(ref.year, ref.month, ref.day)
        .subtract(Duration(days: ref.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final checkInMap = {for (var c in history) c.date: c};
    final List<WeekdayPerformance> days = [];
    const dayLabels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    int scheduledCount = 0;
    int completedCount = 0;

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);
      final isScheduled = isHabitDueOn(habit, dayDate);
      final checkIn = checkInMap[dateStr];
      final isCompleted = checkIn?.status == 'completed';
      final isSkipped = checkIn?.status == 'skipped';

      if (isScheduled) {
        scheduledCount++;
        if (isCompleted) {
          completedCount++;
        }
      }

      days.add(
        WeekdayPerformance(
          weekday: dayDate.weekday,
          dayLabel: dayLabels[dayDate.weekday] ?? '',
          dateStr: dateStr,
          isScheduled: isScheduled,
          isCompleted: isCompleted,
          isSkipped: isSkipped,
          valueLogged: checkIn?.valueLogged,
        ),
      );
    }

    return WeeklyPerformance(
      weekStart: monday,
      weekEnd: sunday,
      days: days,
      scheduledDaysCount: scheduledCount,
      completedDaysCount: completedCount,
    );
  }

  MonthlyPerformance computeMonthlyPerformance(
    Habit habit,
    List<CheckIn> history, [
    DateTime? monthDate,
  ]) {
    final currentMonth = monthDate ?? DateTime.now();
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    final checkInMap = {for (var c in history) c.date: c};

    int scheduled = 0;
    int completed = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      if (isHabitDueOn(habit, date)) {
        scheduled++;
        final dStr = DateFormat('yyyy-MM-dd').format(date);
        if (checkInMap[dStr]?.status == 'completed') {
          completed++;
        }
      }
    }

    final prevMonthFirst = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    final prevMonthLast = DateTime(currentMonth.year, currentMonth.month, 0);
    int prevScheduled = 0;
    int prevCompleted = 0;

    for (int day = 1; day <= prevMonthLast.day; day++) {
      final date = DateTime(prevMonthFirst.year, prevMonthFirst.month, day);
      if (isHabitDueOn(habit, date)) {
        prevScheduled++;
        final dStr = DateFormat('yyyy-MM-dd').format(date);
        if (checkInMap[dStr]?.status == 'completed') {
          prevCompleted++;
        }
      }
    }

    final currentRate = scheduled > 0 ? (completed / scheduled) : 0.0;
    final prevRate = prevScheduled > 0 ? (prevCompleted / prevScheduled) : null;

    return MonthlyPerformance(
      month: firstDay,
      totalDaysInMonth: daysInMonth,
      scheduledDays: scheduled,
      completedDays: completed,
      completionRate: currentRate,
      previousMonthRate: prevRate,
    );
  }

  Future<WeeklyReviewData> computeOverallWeeklyReview([DateTime? referenceDate]) async {
    final ref = referenceDate ?? DateTime.now();
    final monday = DateTime(ref.year, ref.month, ref.day)
        .subtract(Duration(days: ref.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final prevMonday = monday.subtract(const Duration(days: 7));

    final allCheckIns = await database.select(database.checkIns).get();

    int totalScheduledThisWeek = 0;
    int totalCompletedThisWeek = 0;
    int totalScheduledPrevWeek = 0;
    int totalCompletedPrevWeek = 0;

    double totalDuration = 0.0;
    double totalQuantity = 0.0;

    final List<HabitReviewItem> reviewItems = [];

    for (final habit in _habits) {
      final habitHistory = allCheckIns.where((c) => c.habitId == habit.id).toList();
      final thisWeek = computeWeeklyPerformance(habit, habitHistory, monday);
      final prevWeek = computeWeeklyPerformance(habit, habitHistory, prevMonday);

      totalScheduledThisWeek += thisWeek.scheduledDaysCount;
      totalCompletedThisWeek += thisWeek.completedDaysCount;

      totalScheduledPrevWeek += prevWeek.scheduledDaysCount;
      totalCompletedPrevWeek += prevWeek.completedDaysCount;

      for (final day in thisWeek.days) {
        if (day.valueLogged != null) {
          if (habit.habitType == 'duration') {
            totalDuration += day.valueLogged!;
          } else if (habit.habitType == 'quantity') {
            totalQuantity += day.valueLogged!;
          }
        }
      }

      reviewItems.add(
        HabitReviewItem(
          habitId: habit.id,
          habitName: habit.name,
          category: habit.category,
          symbol: habit.symbol,
          colorValue: habit.colorValue,
          scheduledDays: thisWeek.scheduledDaysCount,
          completedDays: thisWeek.completedDaysCount,
          completionRate: thisWeek.completionRate,
        ),
      );
    }

    reviewItems.sort((a, b) => b.completionRate.compareTo(a.completionRate));
    final topHabits = reviewItems.where((h) => h.completionRate >= 0.7).take(5).toList();
    final missedHabits = reviewItems
        .where((h) => h.scheduledDays > 0 && h.completionRate < 0.7)
        .toList()
      ..sort((a, b) => a.completionRate.compareTo(b.completionRate));

    final currentRate = totalScheduledThisWeek > 0
        ? (totalCompletedThisWeek / totalScheduledThisWeek).clamp(0.0, 1.0)
        : 0.0;
    final prevRate = totalScheduledPrevWeek > 0
        ? (totalCompletedPrevWeek / totalScheduledPrevWeek).clamp(0.0, 1.0)
        : null;

    return WeeklyReviewData(
      weekStart: monday,
      weekEnd: sunday,
      totalScheduled: totalScheduledThisWeek,
      totalCompleted: totalCompletedThisWeek,
      completionRate: currentRate,
      previousWeekRate: prevRate,
      topHabits: topHabits,
      missedHabits: missedHabits,
      totalDurationMinutes: totalDuration,
      totalQuantityLogged: totalQuantity,
      activeHabitsCount: _habits.length,
    );
  }

  HabitStats computeHabitStats(Habit habit, List<CheckIn> history) {
    final completed = history
        .where((c) => c.status == 'completed')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final weeklyPerf = computeWeeklyPerformance(habit, history);
    final monthlyPerf = computeMonthlyPerformance(habit, history);

    NumericalGoalProgress? numericalProgress;
    if (habit.targetValue != null && habit.targetValue! > 0) {
      final loggedValues = completed
          .map((c) => c.valueLogged)
          .whereType<double>()
          .toList();

      if (loggedValues.isNotEmpty) {
        final total = loggedValues.reduce((a, b) => a + b);
        final avg = total / loggedValues.length;
        final max = loggedValues.reduce((a, b) => a > b ? a : b);
        numericalProgress = NumericalGoalProgress(
          targetValue: habit.targetValue!,
          unit: habit.unit ?? '',
          totalLogged: total,
          averageLogged: avg,
          highestLogged: max,
          logsCount: loggedValues.length,
        );
      } else {
        numericalProgress = NumericalGoalProgress(
          targetValue: habit.targetValue!,
          unit: habit.unit ?? '',
          totalLogged: 0,
          averageLogged: 0,
          highestLogged: 0,
          logsCount: 0,
        );
      }
    }

    if (completed.isEmpty) {
      return HabitStats(
        currentStreak: 0,
        longestStreak: 0,
        totalCompletions: 0,
        completionRate: 0.0,
        averageDifficulty: 0.0,
        trendMessage: 'No completed sessions logged yet.',
        difficultyDistribution: {'Easy (1-3)': 0, 'Moderate (4-7)': 0, 'Hard (8-10)': 0},
        recentSessions: [],
        weeklyPerformance: weeklyPerf,
        monthlyPerformance: monthlyPerf,
        numericalProgress: numericalProgress,
      );
    }

    final total = completed.length;
    final ratedSessions = completed.where((c) => c.difficulty != null).toList();
    double avgDiff = 0.0;
    int easyCount = 0;
    int modCount = 0;
    int hardCount = 0;

    if (ratedSessions.isNotEmpty) {
      final sum = ratedSessions.fold<int>(0, (acc, c) => acc + (c.difficulty ?? 5));
      avgDiff = sum / ratedSessions.length;

      for (var s in ratedSessions) {
        final d = s.difficulty ?? 5;
        if (d <= 3) {
          easyCount++;
        } else if (d <= 7) {
          modCount++;
        } else {
          hardCount++;
        }
      }
    }

    String trend = 'Baseline establishing';
    if (ratedSessions.length >= 4) {
      final recent = ratedSessions.take(3).map((e) => e.difficulty ?? 5).reduce((a, b) => a + b) / 3;
      final older = ratedSessions.skip(3).take(3).map((e) => e.difficulty ?? 5).reduce((a, b) => a + b) / 3;

      if (recent < older - 0.5) {
        trend = 'Getting easier! Habit mastery improving 🚀';
      } else if (recent > older + 0.5) {
        trend = 'Perceived exertion higher recently 💪';
      } else {
        trend = 'Consistent effort and steady retention 🎯';
      }
    }

    final checkInDateSet = completed.map((c) => c.date).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = 0;
    DateTime checkDate = today;

    final todayDue = isHabitDueOn(habit, today);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    if (todayDue && !checkInDateSet.contains(todayStr)) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    while (true) {
      final isDue = isHabitDueOn(habit, checkDate);
      final dStr = DateFormat('yyyy-MM-dd').format(checkDate);

      if (isDue) {
        if (checkInDateSet.contains(dStr)) {
          currentStreak++;
        } else {
          break;
        }
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
      final startDay = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
      if (checkDate.isBefore(startDay)) {
        break;
      }
    }

    int longest = 0;
    int rollingStreak = 0;

    final startDay = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
    DateTime scanDate = today;
    int scheduledDaysTotal = 0;

    while (!scanDate.isBefore(startDay)) {
      final isDue = isHabitDueOn(habit, scanDate);
      final dStr = DateFormat('yyyy-MM-dd').format(scanDate);

      if (isDue) {
        scheduledDaysTotal++;
        if (checkInDateSet.contains(dStr)) {
          rollingStreak++;
          if (rollingStreak > longest) longest = rollingStreak;
        } else {
          rollingStreak = 0;
        }
      }
      scanDate = scanDate.subtract(const Duration(days: 1));
    }

    if (currentStreak > longest) longest = currentStreak;

    final completionRate = scheduledDaysTotal > 0
        ? (total / scheduledDaysTotal).clamp(0.0, 1.0)
        : 1.0;

    return HabitStats(
      currentStreak: currentStreak,
      longestStreak: longest,
      totalCompletions: total,
      completionRate: completionRate,
      averageDifficulty: avgDiff,
      trendMessage: trend,
      difficultyDistribution: {
        'Easy (1-3)': easyCount,
        'Moderate (4-7)': modCount,
        'Hard (8-10)': hardCount,
      },
      recentSessions: completed.take(14).toList(),
      weeklyPerformance: weeklyPerf,
      monthlyPerformance: monthlyPerf,
      numericalProgress: numericalProgress,
    );
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _archivedSubscription?.cancel();
    _goalsSubscription?.cancel();
    _achievementsSubscription?.cancel();
    _checkInsSubscription?.cancel();
    super.dispose();
  }
}
