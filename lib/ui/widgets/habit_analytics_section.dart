import 'package:flutter/material.dart';
import '../../data/database.dart';
import '../../providers/habit_provider.dart';
import 'apple_glass_card.dart';
import 'difficulty_selector.dart';
import 'progress_bar_chart.dart';
import 'weekly_breakdown_card.dart';

class HabitAnalyticsSection extends StatelessWidget {
  final Habit habit;
  final HabitStats stats;

  const HabitAnalyticsSection({
    super.key,
    required this.habit,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(habit.colorValue);
    final completionPct = (stats.completionRate * 100).round();
    final monthly = stats.monthlyPerformance;
    final numGoal = stats.numericalProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS & STATISTICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Icon(Icons.insights, size: 18, color: habitColor),
          ],
        ),
        const SizedBox(height: 12),

        // Streaks & Consistency Overview Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Current Streak',
                value: '${stats.currentStreak} Days',
                subtitle: habit.scheduleType == 'specific_days'
                    ? 'Scheduled days'
                    : 'Consecutive',
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Best Streak',
                value: '${stats.longestStreak} Days',
                subtitle: 'All-time best',
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Total Logs',
                value: '${stats.totalCompletions}',
                subtitle: '$completionPct% rate',
                icon: Icons.check_circle_outline,
                iconColor: habitColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Weekly Mon-Sun Breakdown Card
        WeeklyBreakdownCard(
          weeklyPerformance: stats.weeklyPerformance,
          habitColor: habitColor,
        ),
        const SizedBox(height: 12),

        // 14-Day Activity Bar Chart
        ProgressBarChart(
          history: stats.recentSessions,
          habitColor: habitColor,
          targetValue: habit.targetValue,
          unit: habit.unit,
        ),
        const SizedBox(height: 12),

        // Monthly Statistics Glass Card
        AppleGlassCard(
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
                      Icon(Icons.calendar_month_outlined,
                          size: 18, color: habitColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Monthly Performance',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: habitColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${monthly.completionPercent}% Consistency',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: habitColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubStat(
                    'Days Completed',
                    '${monthly.completedDays} / ${monthly.scheduledDays}',
                    isDark,
                  ),
                  _buildDivider(isDark),
                  _buildSubStat(
                    'Scheduled Days',
                    '${monthly.scheduledDays} days',
                    isDark,
                  ),
                  _buildDivider(isDark),
                  _buildSubStat(
                    'Monthly Trend',
                    monthly.monthOverMonthDiff != null
                        ? '${monthly.monthOverMonthDiff! >= 0 ? '+' : ''}${(monthly.monthOverMonthDiff! * 100).round()}%'
                        : 'Baseline',
                    isDark,
                    color: monthly.monthOverMonthDiff != null &&
                            monthly.monthOverMonthDiff! >= 0
                        ? const Color(0xFF10B981)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Numerical Goal Tracking Card (if set)
        if (numGoal != null) ...[
          AppleGlassCard(
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
                        Icon(Icons.flag_outlined, size: 18, color: habitColor),
                        const SizedBox(width: 8),
                        Text(
                          'Target: ${numGoal.targetValue.toStringAsFixed(0)} ${numGoal.unit}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Text(
                      '${numGoal.achievementPercent}% Avg',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: habitColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubStat(
                      'Avg per Session',
                      '${numGoal.averageLogged.toStringAsFixed(1)} ${numGoal.unit}',
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSubStat(
                      'Best Session',
                      '${numGoal.highestLogged.toStringAsFixed(0)} ${numGoal.unit}',
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSubStat(
                      'Total Volume',
                      '${numGoal.totalLogged.toStringAsFixed(0)} ${numGoal.unit}',
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Difficulty Mastery & Trend Card
        AppleGlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Perceived Difficulty Score',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DifficultySelector.getColorForDifficulty(
                        stats.averageDifficulty.round(),
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${stats.averageDifficulty.toStringAsFixed(1)} / 10',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: DifficultySelector.getColorForDifficulty(
                          stats.averageDifficulty.round(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stats.trendMessage,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Distribution breakdown
              Row(
                children: stats.difficultyDistribution.entries.map((entry) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubStat(String label, String value, bool isDark,
      {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppleGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      borderRadius: 18,
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
