import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';

class HabitItem {
  final Habit habit;
  final bool isCompletedToday;
  final int? todayDifficulty;
  final String? todayNote;

  HabitItem({
    required this.habit,
    required this.isCompletedToday,
    this.todayDifficulty,
    this.todayNote,
  });
}

class HabitStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final double averageDifficulty;
  final String trendMessage;
  final Map<String, int> difficultyDistribution;
  final List<CheckIn> recentSessions;

  HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.averageDifficulty,
    required this.trendMessage,
    required this.difficultyDistribution,
    required this.recentSessions,
  });
}

class HabitProvider extends ChangeNotifier {
  final AppDatabase database;
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedCategory = 'All';

  List<Habit> _habits = [];
  Map<int, CheckIn> _todayCheckInsMap = {};

  StreamSubscription? _habitsSubscription;
  StreamSubscription? _checkInsSubscription;

  HabitProvider({required this.database}) {
    _initStreams();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get selectedCategory => _selectedCategory;

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
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
    final defaultCategories = ['All', 'General', 'Fitness', 'Health', 'Learning', 'Mindfulness'];
    final existingFromHabits = _habits.map((h) => h.category).toSet();
    final combined = {...defaultCategories, ...existingFromHabits}.toList();
    return combined;
  }

  List<HabitItem> get allHabitItems {
    return _habits.map((habit) {
      final checkIn = _todayCheckInsMap[habit.id];
      return HabitItem(
        habit: habit,
        isCompletedToday: checkIn != null,
        todayDifficulty: checkIn?.difficulty,
        todayNote: checkIn?.note,
      );
    }).toList();
  }

  List<HabitItem> get habitItems {
    final all = allHabitItems;
    if (_selectedCategory == 'All') {
      return all;
    }
    return all.where((item) => item.habit.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  int get totalCount => _habits.length;

  int get completedCount => _todayCheckInsMap.length;

  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  int get progressPercentInt {
    return (progressPercentage * 100).round();
  }

  Future<void> addHabit(
    String name, {
    String category = 'General',
    String symbol = 'check',
    int colorValue = 0xFF10B981,
  }) async {
    if (name.trim().isEmpty) return;
    await database.addHabit(
      name,
      category: category,
      symbol: symbol,
      colorValue: colorValue,
    );
    await refresh();
  }

  Future<void> editHabit(
    int id,
    String newName, {
    String category = 'General',
    String symbol = 'check',
    int colorValue = 0xFF10B981,
  }) async {
    if (newName.trim().isEmpty) return;
    await database.updateHabitDetails(
      id,
      name: newName,
      category: category,
      symbol: symbol,
      colorValue: colorValue,
    );
    await refresh();
  }

  Future<void> deleteHabit(int id) async {
    await database.deleteHabit(id);
    await refresh();
  }

  Future<void> toggleHabitCompletion(int habitId, {int? difficulty = 5}) async {
    await database.toggleCheckIn(habitId, todayString, difficulty: difficulty);
    await refresh();
  }

  Future<void> markHabitDifficulty(int habitId, int difficulty) async {
    await database.setCheckInStatusAndNote(
      habitId,
      todayString,
      status: 'completed',
      difficulty: difficulty,
    );
    await refresh();
  }

  Future<void> completeHabitWithDetails(
    int habitId, {
    required int difficulty,
    String? note,
  }) async {
    await database.setCheckInStatusAndNote(
      habitId,
      todayString,
      status: 'completed',
      difficulty: difficulty,
      note: note,
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
  }) async {
    await database.setCheckInStatusAndNote(
      habitId,
      dateStr,
      status: status,
      note: note,
      difficulty: difficulty,
    );
    await refresh();
  }

  HabitStats computeHabitStats(List<CheckIn> history) {
    final completed = history
        .where((c) => c.status == 'completed')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (completed.isEmpty) {
      return HabitStats(
        currentStreak: 0,
        longestStreak: 0,
        totalCompletions: 0,
        averageDifficulty: 0.0,
        trendMessage: 'No completed sessions logged yet.',
        difficultyDistribution: {'Easy (1-3)': 0, 'Moderate (4-7)': 0, 'Hard (8-10)': 0},
        recentSessions: [],
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

    final dateSet = completed.map((c) => c.date).toSet();
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayFormatted =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    int currentStreak = 0;
    DateTime checkDate = dateSet.contains(todayFormatted)
        ? now
        : dateSet.contains(yesterdayFormatted)
            ? now.subtract(const Duration(days: 1))
            : now;

    if (dateSet.contains(todayFormatted) || dateSet.contains(yesterdayFormatted)) {
      while (true) {
        final dStr = DateFormat('yyyy-MM-dd').format(checkDate);
        if (dateSet.contains(dStr)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    final sortedAsc = completed.map((c) => DateFormat('yyyy-MM-dd').parse(c.date)).toList()
      ..sort();
    int longest = 0;
    int tempStreak = 0;
    DateTime? prev;

    for (final d in sortedAsc) {
      if (prev == null) {
        tempStreak = 1;
      } else {
        final diff = d.difference(prev).inDays;
        if (diff == 1) {
          tempStreak++;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      if (tempStreak > longest) longest = tempStreak;
      prev = d;
    }

    return HabitStats(
      currentStreak: currentStreak,
      longestStreak: longest,
      totalCompletions: total,
      averageDifficulty: avgDiff,
      trendMessage: trend,
      difficultyDistribution: {
        'Easy (1-3)': easyCount,
        'Moderate (4-7)': modCount,
        'Hard (8-10)': hardCount,
      },
      recentSessions: completed.take(14).toList(),
    );
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _checkInsSubscription?.cancel();
    super.dispose();
  }
}
