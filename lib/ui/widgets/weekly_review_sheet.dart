import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weekly_review_model.dart';
import 'apple_glass_card.dart';
import 'habit_symbol_icon.dart';

class WeeklyReviewSheet extends StatelessWidget {
  final WeeklyReviewData reviewData;

  const WeeklyReviewSheet({
    super.key,
    required this.reviewData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startStr = DateFormat('MMM d').format(reviewData.weekStart);
    final endStr = DateFormat('MMM d, y').format(reviewData.weekEnd);
    final diff = reviewData.weekOverWeekDiff;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and date range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Weekly Review',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$startStr – $endStr',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Macro Score Apple Glass Card
              AppleGlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Row(
                  children: [
                    // Big percentage circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${reviewData.completionPercent}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Contextual metrics
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Completion',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reviewData.totalCompleted} of ${reviewData.totalScheduled} scheduled habits done',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          if (diff != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  diff >= 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 13,
                                  color: diff >= 0
                                      ? const Color(0xFF10B981)
                                      : Colors.redAccent,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${(diff.abs() * 100).round()}% ${diff >= 0 ? 'increase' : 'decrease'} vs last week',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: diff >= 0
                                        ? const Color(0xFF10B981)
                                        : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Activity totals (duration & quantity)
              Row(
                children: [
                  if (reviewData.totalDurationMinutes > 0)
                    Expanded(
                      child: AppleGlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time Invested',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${reviewData.totalDurationMinutes.round()} mins',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (reviewData.totalDurationMinutes > 0 &&
                      reviewData.totalQuantityLogged > 0)
                    const SizedBox(width: 10),
                  if (reviewData.totalQuantityLogged > 0)
                    Expanded(
                      child: AppleGlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quantity Logged',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${reviewData.totalQuantityLogged.round()} units',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Top Performing Habits
              if (reviewData.topHabits.isNotEmpty) ...[
                const Text(
                  '🌟 Strongest Consistency',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...reviewData.topHabits.map((item) => _HabitReviewCard(
                      item: item,
                      isPositive: true,
                    )),
                const SizedBox(height: 14),
              ],

              // Habits to Focus On
              if (reviewData.missedHabits.isNotEmpty) ...[
                const Text(
                  '🎯 Growth Opportunities',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...reviewData.missedHabits.map((item) => _HabitReviewCard(
                      item: item,
                      isPositive: false,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitReviewCard extends StatelessWidget {
  final HabitReviewItem item;
  final bool isPositive;

  const _HabitReviewCard({
    required this.item,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(item.colorValue);

    return AppleGlassCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 14,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(
              HabitSymbols.getIcon(item.symbol),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.habitName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.completedDays} / ${item.scheduledDays} days completed',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.completionPercent}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPositive ? const Color(0xFF10B981) : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
