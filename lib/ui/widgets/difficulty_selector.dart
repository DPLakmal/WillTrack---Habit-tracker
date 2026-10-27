import 'package:flutter/material.dart';

class DifficultySelector extends StatelessWidget {
  final int selectedDifficulty;
  final ValueChanged<int> onChanged;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onChanged,
  });

  static Color getColorForDifficulty(int score) {
    if (score <= 3) {
      return const Color(0xFF10B981); // Emerald Green (Easy)
    } else if (score <= 6) {
      return const Color(0xFFF59E0B); // Amber / Yellow (Moderate)
    } else if (score <= 8) {
      return const Color(0xFFF97316); // Orange (Hard)
    } else {
      return const Color(0xFFEF4444); // Red (Very Hard)
    }
  }

  static String getLabelForDifficulty(int score) {
    switch (score) {
      case 1:
      case 2:
        return 'Very Easy (Effortless)';
      case 3:
      case 4:
        return 'Light Effort (Smooth)';
      case 5:
      case 6:
        return 'Moderate (Standard push)';
      case 7:
      case 8:
        return 'Challenging (Pushed limits)';
      case 9:
      case 10:
        return 'Maximum Effort (Exhausting)';
      default:
        return 'Moderate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = getColorForDifficulty(selectedDifficulty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Perceived Difficulty (1-10)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activeColor, width: 1.5),
              ),
              child: Text(
                '$selectedDifficulty / 10',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1-10 Buttons row
        SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final score = index + 1;
              final isSelected = score == selectedDifficulty;
              final color = getColorForDifficulty(score);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onChanged(score),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),

        // Text summary of difficulty
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: activeColor),
            const SizedBox(width: 6),
            Text(
              getLabelForDifficulty(selectedDifficulty),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: activeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
