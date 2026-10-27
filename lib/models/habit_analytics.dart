class WeekdayPerformance {
  final int weekday; // 1 = Mon ... 7 = Sun
  final String dayLabel; // "Mon", "Tue", etc.
  final String dateStr; // "2026-10-27"
  final bool isScheduled;
  final bool isCompleted;
  final bool isSkipped;
  final double? valueLogged;

  const WeekdayPerformance({
    required this.weekday,
    required this.dayLabel,
    required this.dateStr,
    required this.isScheduled,
    required this.isCompleted,
    required this.isSkipped,
    this.valueLogged,
  });

  bool get isSuccessful => isCompleted;
  bool get isFailed => isScheduled && !isCompleted && !isFuture;
  bool get isFuture {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return d.isAfter(today);
  }
}

class WeeklyPerformance {
  final DateTime weekStart; // Monday
  final DateTime weekEnd; // Sunday
  final List<WeekdayPerformance> days;
  final int scheduledDaysCount;
  final int completedDaysCount;

  const WeeklyPerformance({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.scheduledDaysCount,
    required this.completedDaysCount,
  });

  double get completionRate {
    if (scheduledDaysCount == 0) return 0.0;
    return (completedDaysCount / scheduledDaysCount).clamp(0.0, 1.0);
  }

  int get completionPercent => (completionRate * 100).round();
}

class MonthlyPerformance {
  final DateTime month;
  final int totalDaysInMonth;
  final int scheduledDays;
  final int completedDays;
  final double completionRate;
  final double? previousMonthRate;

  const MonthlyPerformance({
    required this.month,
    required this.totalDaysInMonth,
    required this.scheduledDays,
    required this.completedDays,
    required this.completionRate,
    this.previousMonthRate,
  });

  int get completionPercent => (completionRate * 100).round();

  double? get monthOverMonthDiff {
    if (previousMonthRate == null) return null;
    return completionRate - previousMonthRate!;
  }
}

class NumericalGoalProgress {
  final double targetValue;
  final String unit;
  final double totalLogged;
  final double averageLogged;
  final double highestLogged;
  final int logsCount;

  const NumericalGoalProgress({
    required this.targetValue,
    required this.unit,
    required this.totalLogged,
    required this.averageLogged,
    required this.highestLogged,
    required this.logsCount,
  });

  double get achievementRate {
    if (targetValue == 0) return 1.0;
    return (averageLogged / targetValue).clamp(0.0, 2.0);
  }

  int get achievementPercent => (achievementRate * 100).round();
}
