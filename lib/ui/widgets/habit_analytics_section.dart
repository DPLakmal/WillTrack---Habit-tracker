import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import '../../providers/habit_provider.dart';
import 'difficulty_selector.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habitColor = Color(habit.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS & DIFFICULTY ANALYSIS',
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
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Longest Streak',
                value: '${stats.longestStreak} Days',
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.amber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Total Logs',
                value: '${stats.totalCompletions}',
                icon: Icons.check_circle_outline,
                iconColor: habitColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Difficulty Mastery & Trend Card
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DifficultySelector.getColorForDifficulty(
                          stats.averageDifficulty.round(),
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stats.averageDifficulty == 0.0
                            ? 'N/A'
                            : '${stats.averageDifficulty.toStringAsFixed(1)} / 10',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: DifficultySelector.getColorForDifficulty(
                            stats.averageDifficulty.round(),
                          ),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Trend insight badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stats.trendMessage,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Difficulty Distribution
                const Text(
                  'Effort Breakdown',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...stats.difficultyDistribution.entries.map((entry) {
                  final count = entry.value;
                  final total = stats.totalCompletions == 0 ? 1 : stats.totalCompletions;
                  final pct = (count / total).clamp(0.0, 1.0);
                  Color barColor = Colors.green;
                  if (entry.key.contains('Moderate')) barColor = Colors.amber;
                  if (entry.key.contains('Hard')) barColor = Colors.redAccent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '$count session${count == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 6,
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Recent 14 Sessions Difficulty Trend Bars
        if (stats.recentSessions.isNotEmpty) ...[
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Sessions Difficulty Trend (Last 14)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: stats.recentSessions.reversed.map((session) {
                        final diff = session.difficulty ?? 5;
                        final heightFactor = (diff / 10.0).clamp(0.1, 1.0);
                        final barColor = DifficultySelector.getColorForDifficulty(diff);
                        final date = DateFormat('yyyy-MM-dd').parse(session.date);

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$diff',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: barColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 14,
                              height: 65 * heightFactor,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('d/M').format(date),
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
