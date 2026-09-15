import 'package:flutter/material.dart';

class SpiritualPathDay {
  final int number;
  final String title;
  final String subtitle;
  final String scriptureReference;
  final String scripture;
  final String reflection;
  final String prayer;
  final String practice;

  const SpiritualPathDay({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.scriptureReference,
    required this.scripture,
    required this.reflection,
    required this.prayer,
    required this.practice,
  });

  String get narration =>
      '$title. $scriptureReference. $scripture. Reflexión. $reflection. '
      'Oración. $prayer. Paso de hoy. $practice';
}

class SpiritualPath {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final int minutesPerDay;
  final IconData icon;
  final Color accent;
  final List<SpiritualPathDay> days;

  const SpiritualPath({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.minutesPerDay,
    required this.icon,
    required this.accent,
    required this.days,
  });
}

class SpiritualPathProgress {
  final String pathId;
  final Set<int> completedDays;
  final DateTime? startedAt;
  final DateTime? lastCompletedAt;

  const SpiritualPathProgress({
    required this.pathId,
    this.completedDays = const {},
    this.startedAt,
    this.lastCompletedAt,
  });

  double progressFor(int totalDays) => totalDays == 0
      ? 0
      : (completedDays.length / totalDays).clamp(0, 1).toDouble();

  int nextDay(int totalDays) {
    for (var day = 1; day <= totalDays; day++) {
      if (!completedDays.contains(day)) return day;
    }
    return totalDays;
  }

  bool isComplete(int totalDays) =>
      totalDays > 0 && completedDays.length >= totalDays;
}
