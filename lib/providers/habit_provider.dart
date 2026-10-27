import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../models/habit_analytics.dart';
import '../services/notification_service.dart';

class HabitItem {
  final Habit habit;
  final bool isCompletedToday;
  final int? todayDifficulty;
  final String? todayNote;
  final double? todayValueLogged;
  final bool isDueToday;

  HabitItem({
    required this.habit,
    required this.isCompletedToday,
    this.todayDifficulty,
    this.todayNote,
    this.todayValueLogged,
    this.isDueToday = true,
  });
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
  bool _areNotificationsEnabled = true;

  List<Habit> _habits = [];
  List<Habit> _archivedHabits = [];
  Map<int, CheckIn> _todayCheckInsMap = {};

  StreamSubscription? _habitsSubscription;
  StreamSubscription? _archivedSubscription;
  StreamSubscription? _checkInsSubscription;

  HabitProvider({required this.database}) {
    _initStreams();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get selectedCategory => _selectedCategory;
  bool get areNotificationsEnabled => _areNotificationsEnabled;
  List<Habit> get archivedHabits => _archivedHabits;

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
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

  String get todayString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _initStreams() {
    _habitsSubscription = database.watchActiveHabits().listen((habits) {
      _habits = habits;
      notifyListeners();
    });

    _archivedSubscription = database.watchArchivedHabits().listen((archived) {
      _archivedHabits = archived;
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
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    _habits = await database.getActiveHabits();
    _archivedHabits = await database.getArchivedHabits();
    final todayList = await (database.select(database.checkIns)
          ..where((tbl) => tbl.date.equals(todayString)))
        .get();
    _todayCheckInsMap = {
      for (var c in todayList)
        if (c.status == 'completed') c.habitId: c,
    };
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
    return _habits.map((habit) {
      final checkIn = _todayCheckInsMap[habit.id];
      final isDue = isHabitDueOn(habit, now);

      return HabitItem(
        habit: habit,
        isCompletedToday: checkIn != null,
        todayDifficulty: checkIn?.difficulty,
        todayNote: checkIn?.note,
        todayValueLogged: checkIn?.valueLogged,
        isDueToday: isDue,
      );
    }).toList();
  }

  /// Habits filtered by category and due today
  List<HabitItem> get habitItems {
    final all = allHabitItems;
    var filtered = all;

    if (_selectedCategory != 'All') {
      filtered = all
          .where((item) =>
              item.habit.category.toLowerCase() == _selectedCategory.toLowerCase())
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

  WeeklyPerformance computeWeeklyPerformance(
    Habit habit,
    List<CheckIn> history, [
    DateTime? referenceDate,
  ]) {
    final ref = referenceDate ?? DateTime.now();
    // In Dart weekday: 1 = Mon ... 7 = Sun
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

    // Previous month rate
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

  HabitStats computeHabitStats(Habit habit, List<CheckIn> history) {
    final completed = history
        .where((c) => c.status == 'completed')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final weeklyPerf = computeWeeklyPerformance(habit, history);
    final monthlyPerf = computeMonthlyPerformance(habit, history);

    // Numerical Goal Progress if habit has targetValue
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

    // Schedule-Aware Streak Calculation
    final checkInDateSet = completed.map((c) => c.date).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Current Streak (skips non-scheduled days without breaking the streak)
    int currentStreak = 0;
    DateTime checkDate = today;

    // If today is scheduled and not completed yet, start check from yesterday
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
          // Missed a scheduled active day -> streak ends
          break;
        }
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
      // Don't go before habit start date
      final startDay = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
      if (checkDate.isBefore(startDay)) {
        break;
      }
    }

    // Longest Streak (schedule-aware)
    int longest = 0;
    int rollingStreak = 0;

    // Scan backwards from today to habit start date or oldest check-in
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

    // Overall completion rate based on scheduled days to date
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
    _checkInsSubscription?.cancel();
    super.dispose();
  }
}
