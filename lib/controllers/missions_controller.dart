import 'package:flutter/material.dart';

class Mission {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int durationMinutes;
  final bool isOptional;
  final String? content;
  bool completed;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.durationMinutes = 2,
    this.isOptional = false,
    this.content,
    this.completed = false,
  });
}

class MissionsController {
  final List<Mission> missions;

  MissionsController({required this.missions});

  void completeMission(String id) {
    final mission = missions.where((m) => m.id == id).firstOrNull;
    if (mission != null) {
      mission.completed = true;
    }
  }

  List<Mission> get essentialMissions =>
      missions.where((mission) => !mission.isOptional).toList();

  int get completedEssentialCount =>
      essentialMissions.where((mission) => mission.completed).length;

  Mission? get nextEssentialMission {
    for (final mission in essentialMissions) {
      if (!mission.completed) return mission;
    }
    return null;
  }

  /// El cierre nocturno es una invitación adicional: no bloquea la racha.
  bool isAllCompleted() => essentialMissions.every((m) => m.completed);
}
