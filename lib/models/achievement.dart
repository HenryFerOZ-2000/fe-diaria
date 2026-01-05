import 'package:flutter/material.dart';
import 'spiritual_stats.dart';

enum AchievementType {
  streak,
  verses,
  prayers,
  posts,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int target;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.icon,
  });

  bool isUnlocked(SpiritualStats stats) {
    switch (type) {
      case AchievementType.streak:
        return stats.currentStreak >= target;
      case AchievementType.verses:
        return stats.versesRead >= target;
      case AchievementType.prayers:
        return stats.prayersCompleted >= target;
      case AchievementType.posts:
        return stats.postsCreated >= target;
    }
  }

  int getProgress(SpiritualStats stats) {
    switch (type) {
      case AchievementType.streak:
        return stats.currentStreak;
      case AchievementType.verses:
        return stats.versesRead;
      case AchievementType.prayers:
        return stats.prayersCompleted;
      case AchievementType.posts:
        return stats.postsCreated;
    }
  }
}

