import 'package:flutter/material.dart';

class Mission {
  final String id;
  final String title;
  final IconData icon;
  bool completed;

  Mission({
    required this.id,
    required this.title,
    required this.icon,
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

  bool isAllCompleted() => missions.every((m) => m.completed);
}

