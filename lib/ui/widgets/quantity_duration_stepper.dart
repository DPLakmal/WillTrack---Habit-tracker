import 'dart:async';
import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final double currentLogged;
  final double targetValue;
  final String unit;
  final Color activeColor;
  final ValueChanged<double> onIncrement;
  final ValueChanged<double> onSetValue;

  const QuantityStepper({
    super.key,
    required this.currentLogged,
    required this.targetValue,
    required this.unit,
    required this.activeColor,
    required this.onIncrement,
    required this.onSetValue,
  });

  String _formatNumber(double val) {
    if (val % 1 == 0) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  void _showSetDialog(BuildContext context) {
    final controller = TextEditingController(text: _formatNumber(currentLogged));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log $unit'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Value ($unit)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: activeColor),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null) {
                onSetValue(val);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTargetReached = targetValue > 0 && currentLogged >= targetValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isTargetReached
            ? activeColor.withValues(alpha: 0.16)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTargetReached
              ? activeColor.withValues(alpha: 0.35)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          _CircleButton(
            icon: Icons.remove,
            color: activeColor,
            onPressed: currentLogged > 0 ? () => onIncrement(-1.0) : null,
          ),
          const SizedBox(width: 8),

          // Count Display (Tap to manual edit)
          GestureDetector(
            onTap: () => _showSetDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatNumber(currentLogged),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isTargetReached
                        ? activeColor
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                if (targetValue > 0) ...[
                  Text(
                    ' / ${_formatNumber(targetValue)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Increment button
          _CircleButton(
            icon: Icons.add,
            color: activeColor,
            onPressed: () => onIncrement(1.0),
          ),
        ],
      ),
    );
  }
}

class DurationStepper extends StatefulWidget {
  final double currentLogged;
  final double targetMinutes;
  final String unit;
  final Color activeColor;
  final ValueChanged<double> onAddMinutes;

  const DurationStepper({
    super.key,
    required this.currentLogged,
    required this.targetMinutes,
    required this.unit,
    required this.activeColor,
    required this.onAddMinutes,
  });

  @override
  State<DurationStepper> createState() => _DurationStepperState();
}

class _DurationStepperState extends State<DurationStepper> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      final minutesLogged = (_secondsElapsed / 60.0);
      if (minutesLogged > 0) {
        widget.onAddMinutes(minutesLogged);
      }
      setState(() {
        _isRunning = false;
        _secondsElapsed = 0;
      });
    } else {
      setState(() {
        _isRunning = true;
        _secondsElapsed = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _secondsElapsed++;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTargetReached =
        widget.targetMinutes > 0 && widget.currentLogged >= widget.targetMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isTargetReached
            ? widget.activeColor.withValues(alpha: 0.16)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTargetReached
              ? widget.activeColor.withValues(alpha: 0.35)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stopwatch Icon / Active timer toggle
          GestureDetector(
            onTap: _toggleTimer,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRunning
                    ? Colors.red.withValues(alpha: 0.2)
                    : widget.activeColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 16,
                color: _isRunning ? Colors.red : widget.activeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Duration Text or Live Timer
          if (_isRunning) ...[
            Text(
              _formatTimer(_secondsElapsed),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.redAccent,
              ),
            ),
          ] else ...[
            Text(
              '${widget.currentLogged.round()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isTargetReached
                    ? widget.activeColor
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            if (widget.targetMinutes > 0) ...[
              Text(
                ' / ${widget.targetMinutes.round()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(width: 4),
            Text(
              widget.unit,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.activeColor,
              ),
            ),
          ],
          const SizedBox(width: 8),

          // Quick +15m button
          GestureDetector(
            onTap: () => widget.onAddMinutes(15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+15m',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.activeColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _CircleButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? color.withValues(alpha: 0.15)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? color
              : (isDark ? Colors.grey[600] : Colors.grey[400]),
        ),
      ),
    );
  }
}
