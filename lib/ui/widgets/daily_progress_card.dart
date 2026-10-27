import 'package:flutter/material.dart';

class DailyProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;
  final int percentage;

  const DailyProgressCard({
    super.key,
    required this.completed,
    required this.total,
    required this.progress,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Progress",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: percentage == 100 && total > 0
                        ? Colors.green.withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completed/$total ($percentage%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: percentage == 100 && total > 0
                          ? Colors.green
                          : theme.colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : progress,
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage == 100 && total > 0
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              total == 0
                  ? 'No habits scheduled for today'
                  : completed == total
                      ? '🎉 All done for today! Keep it up!'
                      : '${total - completed} remaining habit${total - completed == 1 ? '' : 's'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
