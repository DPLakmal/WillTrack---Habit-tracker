import 'package:flutter/material.dart';
import '../../models/habit_analytics.dart';
import 'apple_glass_card.dart';

class WeeklyBreakdownCard extends StatelessWidget {
  final WeeklyPerformance weeklyPerformance;
  final Color habitColor;

  const WeeklyBreakdownCard({
    super.key,
    required this.weeklyPerformance,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = weeklyPerformance.completionPercent;

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
                  Icon(Icons.date_range_outlined, size: 18, color: habitColor),
                  const SizedBox(width: 8),
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percent >= 80
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (percent >= 50
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: percent >= 80
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : (percent >= 50
                            ? Colors.amber.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.25)),
                  ),
                ),
                child: Text(
                  '$percent% Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: percent >= 80
                        ? const Color(0xFF10B981)
                        : (percent >= 50 ? Colors.amber[700] : Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekday pills: Mon - Sun
          Row(
            children: weeklyPerformance.days.map((day) {
              final isToday = day.dateStr ==
                  DateTime.now().toIso8601String().substring(0, 10);

              Color statusBg;
              Color statusColor;
              IconData statusIcon;

              if (!day.isScheduled) {
                // Non-scheduled day
                statusBg = isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02);
                statusColor = isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8);
                statusIcon = Icons.remove;
              } else if (day.isCompleted) {
                // Completed day
                statusBg = const Color(0xFF10B981).withValues(alpha: 0.16);
                statusColor = const Color(0xFF10B981);
                statusIcon = Icons.check;
              } else if (day.isFuture) {
                // Future scheduled day
                statusBg = isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04);
                statusColor = isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B);
                statusIcon = Icons.circle_outlined;
              } else {
                // Missed day
                statusBg = Colors.red.withValues(alpha: 0.12);
                statusColor = Colors.red;
                statusIcon = Icons.close;
              }

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? habitColor.withValues(alpha: 0.8)
                          : (day.isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : (day.isFailed
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : Colors.transparent)),
                      width: isToday ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day.dayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday
                              ? habitColor
                              : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      if (day.valueLogged != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          day.valueLogged!.toStringAsFixed(day.valueLogged!.truncateToDouble() == day.valueLogged ? 0 : 1),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${weeklyPerformance.completedDaysCount} of ${weeklyPerformance.scheduledDaysCount} scheduled days completed',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              Text(
                'Weekly completion: $percent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
