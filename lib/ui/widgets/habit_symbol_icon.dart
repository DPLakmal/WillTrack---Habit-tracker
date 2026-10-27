import 'package:flutter/material.dart';

class HabitSymbols {
  static const List<HabitSymbolOption> options = [
    HabitSymbolOption(key: 'check', label: 'Checkmark', icon: Icons.check),
    HabitSymbolOption(key: 'star', label: 'Star', icon: Icons.star),
    HabitSymbolOption(key: 'fire', label: 'Fire / Streak', icon: Icons.local_fire_department),
    HabitSymbolOption(key: 'water', label: 'Water / Hydration', icon: Icons.water_drop),
    HabitSymbolOption(key: 'fitness', label: 'Fitness / Gym', icon: Icons.fitness_center),
    HabitSymbolOption(key: 'heart', label: 'Health / Heart', icon: Icons.favorite),
    HabitSymbolOption(key: 'book', label: 'Reading / Study', icon: Icons.menu_book),
    HabitSymbolOption(key: 'target', label: 'Target / Goal', icon: Icons.track_changes),
    HabitSymbolOption(key: 'pool', label: 'Swimming', icon: Icons.pool),
    HabitSymbolOption(key: 'bed', label: 'Sleep / Rest', icon: Icons.bedtime),
    HabitSymbolOption(key: 'code', label: 'Coding / Tech', icon: Icons.code),
    HabitSymbolOption(key: 'meditate', label: 'Mindfulness', icon: Icons.self_improvement),
  ];

  static IconData getIcon(String? key) {
    for (final opt in options) {
      if (opt.key == key) return opt.icon;
    }
    return Icons.check;
  }
}

class HabitSymbolOption {
  final String key;
  final String label;
  final IconData icon;

  const HabitSymbolOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class HabitColors {
  static const List<int> palette = [
    0xFF10B981, // Emerald green (default)
    0xFF06B6D4, // Cyan / Aqua (great for swimming)
    0xFF3B82F6, // Blue
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFFEF4444, // Red
    0xFFF97316, // Orange
    0xFFEAB308, // Amber / Yellow
  ];
}
