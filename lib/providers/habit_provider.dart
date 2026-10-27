import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';

class HabitItem {
  final Habit habit;
  final bool isCompletedToday;

  HabitItem({
    required this.habit,
    required this.isCompletedToday,
  });
}

class HabitProvider extends ChangeNotifier {
  final AppDatabase database;
  ThemeMode _themeMode = ThemeMode.system;

  List<Habit> _habits = [];
  List<int> _todayCompletedHabitIds = [];

  StreamSubscription? _habitsSubscription;
  StreamSubscription? _checkInsSubscription;

  HabitProvider({required this.database}) {
    _initStreams();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  String get todayString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _initStreams() {
    _habitsSubscription = database.watchActiveHabits().listen((habits) {
      _habits = habits;
      notifyListeners();
    });

    _checkInsSubscription =
        database.watchCompletedHabitIdsForDate(todayString).listen((completedIds) {
      _todayCompletedHabitIds = completedIds;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    _habits = await database.getActiveHabits();
    _todayCompletedHabitIds = await database.getCompletedHabitIdsForDate(todayString);
    notifyListeners();
  }

  List<HabitItem> get habitItems {
    final completedSet = _todayCompletedHabitIds.toSet();
    return _habits.map((habit) {
      return HabitItem(
        habit: habit,
        isCompletedToday: completedSet.contains(habit.id),
      );
    }).toList();
  }

  int get totalCount => _habits.length;

  int get completedCount {
    final habitIdSet = _habits.map((h) => h.id).toSet();
    return _todayCompletedHabitIds.where((id) => habitIdSet.contains(id)).length;
  }

  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  int get progressPercentInt {
    return (progressPercentage * 100).round();
  }

  Future<void> addHabit(String name) async {
    if (name.trim().isEmpty) return;
    await database.addHabit(name);
    await refresh();
  }

  Future<void> editHabit(int id, String newName) async {
    if (newName.trim().isEmpty) return;
    await database.updateHabitName(id, newName);
    await refresh();
  }

  Future<void> deleteHabit(int id) async {
    await database.deleteHabit(id);
    await refresh();
  }

  Future<void> toggleHabitCompletion(int habitId) async {
    await database.toggleCheckIn(habitId, todayString);
    await refresh();
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _checkInsSubscription?.cancel();
    super.dispose();
  }
}
