import 'package:flutter/material.dart';
import '../../data/database.dart';
import 'difficulty_selector.dart';
import 'habit_symbol_icon.dart';

class QuickCheckInDialog extends StatefulWidget {
  final Habit habit;
  final CheckIn? existingCheckIn;
  final Future<void> Function({required int difficulty, String? note}) onConfirm;

  const QuickCheckInDialog({
    super.key,
    required this.habit,
    this.existingCheckIn,
    required this.onConfirm,
  });

  @override
  State<QuickCheckInDialog> createState() => _QuickCheckInDialogState();
}

class _QuickCheckInDialogState extends State<QuickCheckInDialog> {
  late int _difficulty;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.existingCheckIn?.difficulty ?? 5;
    _noteController =
        TextEditingController(text: widget.existingCheckIn?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final habitColor = Color(habit.colorValue);
    final symbolIcon = HabitSymbols.getIcon(habit.symbol);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: habitColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(symbolIcon, color: habitColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Record Today\'s Session',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DifficultySelector(
              selectedDifficulty: _difficulty,
              onChanged: (val) {
                setState(() {
                  _difficulty = val;
                });
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Session Notes (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Felt great, finished 2km, or heavy resistance',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: habitColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            await widget.onConfirm(
              difficulty: _difficulty,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Complete Habit'),
        ),
      ],
    );
  }
}
