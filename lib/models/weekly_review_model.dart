class HabitReviewItem {
  final int habitId;
  final String habitName;
  final String category;
  final String symbol;
  final int colorValue;
  final int scheduledDays;
  final int completedDays;
  final double completionRate;

  const HabitReviewItem({
    required this.habitId,
    required this.habitName,
    required this.category,
    required this.symbol,
    required this.colorValue,
    required this.scheduledDays,
    required this.completedDays,
    required this.completionRate,
  });

  int get completionPercent => (completionRate * 100).round();
}

class WeeklyReviewData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalScheduled;
  final int totalCompleted;
  final double completionRate;
  final double? previousWeekRate;
  final List<HabitReviewItem> topHabits;
  final List<HabitReviewItem> missedHabits;
  final double totalDurationMinutes;
  final double totalQuantityLogged;
  final int activeHabitsCount;

  const WeeklyReviewData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalScheduled,
    required this.totalCompleted,
    required this.completionRate,
    this.previousWeekRate,
    required this.topHabits,
    required this.missedHabits,
    required this.totalDurationMinutes,
    required this.totalQuantityLogged,
    required this.activeHabitsCount,
  });

  int get completionPercent => (completionRate * 100).round();

  double? get weekOverWeekDiff {
    if (previousWeekRate == null) return null;
    return completionRate - previousWeekRate!;
  }
}
