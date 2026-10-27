import 'package:flutter/material.dart';

class Achievement {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final int targetValue;
  final DateTime? unlockedAt;

  const Achievement({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.targetValue,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({DateTime? unlockedAt}) {
    return Achievement(
      key: key,
      title: title,
      description: description,
      icon: icon,
      category: category,
      targetValue: targetValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

class AchievementCatalog {
  static const List<Achievement> all = [
    Achievement(
      key: 'first_step',
      title: 'First Step',
      description: 'Logged your very first habit check-in.',
      icon: Icons.military_tech_rounded,
      category: 'Milestones',
      targetValue: 1,
    ),
    Achievement(
      key: 'streak_3',
      title: '3-Day Spark',
      description: 'Maintained a 3-day consistency streak.',
      icon: Icons.local_fire_department_rounded,
      category: 'Streaks',
      targetValue: 3,
    ),
    Achievement(
      key: 'streak_7',
      title: 'Week Warrior',
      description: 'Kept a 7-day streak going strong.',
      icon: Icons.bolt_rounded,
      category: 'Streaks',
      targetValue: 7,
    ),
    Achievement(
      key: 'streak_30',
      title: 'Habit Master',
      description: 'Reached an unbroken 30-day streak.',
      icon: Icons.workspace_premium_rounded,
      category: 'Streaks',
      targetValue: 30,
    ),
    Achievement(
      key: 'century_100',
      title: 'Century Club',
      description: 'Completed 100 total habit check-ins.',
      icon: Icons.stars_rounded,
      category: 'Milestones',
      targetValue: 100,
    ),
    Achievement(
      key: 'perfect_day',
      title: 'Flawless Day',
      description: 'Completed all scheduled habits in a single day.',
      icon: Icons.verified_rounded,
      category: 'Consistency',
      targetValue: 1,
    ),
    Achievement(
      key: 'early_bird',
      title: 'Early Riser',
      description: 'Completed a Morning Routine habit before 9:00 AM.',
      icon: Icons.wb_sunny_rounded,
      category: 'Routines',
      targetValue: 1,
    ),
    Achievement(
      key: 'night_owl',
      title: 'Evening Serenity',
      description: 'Completed an Evening Routine habit after 8:00 PM.',
      icon: Icons.nightlight_round,
      category: 'Routines',
      targetValue: 1,
    ),
    Achievement(
      key: 'habit_stacker',
      title: 'Flow State',
      description: 'Completed a habit linked to an anchor habit.',
      icon: Icons.link_rounded,
      category: 'Routines',
      targetValue: 1,
    ),
    Achievement(
      key: 'goal_setter',
      title: 'Visionary',
      description: 'Connected a habit to a long-term goal.',
      icon: Icons.flag_circle_rounded,
      category: 'Goals',
      targetValue: 1,
    ),
    Achievement(
      key: 'target_crusher',
      title: 'Target Hit',
      description: 'Reached your quantity or duration goal 5 times.',
      icon: Icons.track_changes_rounded,
      category: 'Milestones',
      targetValue: 5,
    ),
  ];
}
