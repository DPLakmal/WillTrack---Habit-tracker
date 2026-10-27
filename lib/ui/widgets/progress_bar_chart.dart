import 'package:flutter/material.dart';
import '../../data/database.dart';
import 'apple_glass_card.dart';

class ProgressBarChart extends StatelessWidget {
  final List<CheckIn> history;
  final Color habitColor;
  final double? targetValue;
  final String? unit;

  const ProgressBarChart({
    super.key,
    required this.history,
    required this.habitColor,
    this.targetValue,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Last 14 days data points
    final checkInMap = {for (var c in history) c.date: c};
    final List<Map<String, dynamic>> points = [];

    double maxVal = targetValue ?? 10.0;
    for (int i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dStr =
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final checkIn = checkInMap[dStr];
      final isDone = checkIn?.status == 'completed';
      final val = checkIn?.valueLogged ?? (isDone ? (targetValue ?? 1.0) : 0.0);
      if (val > maxVal) maxVal = val;

      points.add({
        'day': d.day,
        'weekday': ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1],
        'isDone': isDone,
        'val': val,
        'diff': checkIn?.difficulty,
      });
    }

    return AppleGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 18, color: habitColor),
                  const SizedBox(width: 8),
                  const Text(
                    '14-Day Activity Trend',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              if (targetValue != null && unit != null)
                Text(
                  'Goal: ${targetValue!.toStringAsFixed(0)} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: habitColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // 14 Bar Columns
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((p) {
                final isDone = p['isDone'] as bool;
                final val = p['val'] as double;
                final ratio = maxVal > 0 ? (val / maxVal).clamp(0.08, 1.0) : 0.08;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: isDone ? (80 * ratio) : 6.0,
                              decoration: BoxDecoration(
                                gradient: isDone
                                    ? LinearGradient(
                                        colors: [
                                          habitColor.withValues(alpha: 0.7),
                                          habitColor,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      )
                                    : null,
                                color: isDone
                                    ? null
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06)),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: isDone
                                    ? [
                                        BoxShadow(
                                          color: habitColor.withValues(alpha: 0.35),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p['weekday'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                            color: isDone
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
