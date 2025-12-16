import 'dart:async';
import 'package:flutter/foundation.dart';

class StreakDay {
  final String label; // "L", "Ma", ...
  final bool completed;

  const StreakDay({
    required this.label,
    required this.completed,
  });
}

class StreakController extends ChangeNotifier {
  int totalDays = 0;
  bool playAnimation = false;
  bool showPopup = false;

  List<StreakDay> days = const [
    StreakDay(label: 'L', completed: false),
    StreakDay(label: 'Ma', completed: false),
    StreakDay(label: 'Mi', completed: false),
    StreakDay(label: 'J', completed: false),
    StreakDay(label: 'V', completed: false),
    StreakDay(label: 'S', completed: false),
    StreakDay(label: 'D', completed: false),
  ];

  void completeToday(int index) {
    if (index < 0 || index >= days.length) return;
    // Evitar completar dos veces el mismo día.
    if (days[index].completed) {
      return;
    }
    final updated = List<StreakDay>.from(days);
    updated[index] = StreakDay(label: updated[index].label, completed: true);
    days = updated;
    totalDays += 1;
    _triggerAnimation();
    showPopup = true;
    notifyListeners();
  }

  void _triggerAnimation() {
    playAnimation = true;
    notifyListeners();
    Timer(const Duration(seconds: 2), () {
      playAnimation = false;
      notifyListeners();
    });
  }

  void consumePopup() {
    if (!showPopup) return;
    showPopup = false;
    notifyListeners();
  }
}

