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
  String _selectedCategory = 'All';

  List<Habit> _habits = [];
  List<int> _todayCompletedHabitIds = [];

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

  List<String> get categories {
    final defaultCategories = ['All', 'General', 'Fitness', 'Health', 'Learning', 'Mindfulness'];
    final existingFromHabits = _habits.map((h) => h.category).toSet();
    final combined = {...defaultCategories, ...existingFromHabits}.toList();
    return combined;
  }

  List<HabitItem> get allHabitItems {
    final completedSet = _todayCompletedHabitIds.toSet();
    return _habits.map((habit) {
      return HabitItem(
        habit: habit,
        isCompletedToday: completedSet.contains(habit.id),
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

  Future<void> toggleHabitCompletion(int habitId) async {
    await database.toggleCheckIn(habitId, todayString);
    await refresh();
  }

  Stream<List<CheckIn>> watchHabitHistory(int habitId) {
    return database.watchCheckInsForHabit(habitId);
  }

  Future<void> updateDayLog(
    int habitId,
    String dateStr, {
    required String status,
    String? note,
  }) async {
    await database.setCheckInStatusAndNote(
      habitId,
      dateStr,
      status: status,
      note: note,
    );
    await refresh();
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _checkInsSubscription?.cancel();
    super.dispose();
  }
}
