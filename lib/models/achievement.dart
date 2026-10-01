import 'spiritual_stats.dart';
import '../design_system/icons/verbum_icons.dart';

enum AchievementType { streak, verses, prayers, posts }

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int target;
  final VerbumIcons icon;

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

/// Logros disponibles, en el orden en que se muestran.
const achievementCatalog = <Achievement>[
  Achievement(
    id: 'streak_7',
    title: 'Constancia de 7 días',
    description: 'Mantén tu constancia 7 días seguidos',
    type: AchievementType.streak,
    target: 7,
    icon: VerbumIcons.flame,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Constancia de 30 días',
    description: 'Mantén tu constancia 30 días seguidos',
    type: AchievementType.streak,
    target: 30,
    icon: VerbumIcons.flame,
  ),
  Achievement(
    id: 'streak_100',
    title: 'Constancia de 100 días',
    description: 'Mantén tu constancia 100 días seguidos',
    type: AchievementType.streak,
    target: 100,
    icon: VerbumIcons.flame,
  ),
  Achievement(
    id: 'verses_10',
    title: '10 Versículos',
    description: 'Lee 10 versículos',
    type: AchievementType.verses,
    target: 10,
    icon: VerbumIcons.bookOpenText,
  ),
  Achievement(
    id: 'verses_100',
    title: '100 Versículos',
    description: 'Lee 100 versículos',
    type: AchievementType.verses,
    target: 100,
    icon: VerbumIcons.bookOpenText,
  ),
  Achievement(
    id: 'verses_500',
    title: '500 Versículos',
    description: 'Lee 500 versículos',
    type: AchievementType.verses,
    target: 500,
    icon: VerbumIcons.bookOpenText,
  ),
  Achievement(
    id: 'prayers_10',
    title: '10 Oraciones',
    description: 'Completa 10 oraciones',
    type: AchievementType.prayers,
    target: 10,
    icon: VerbumIcons.handsPraying,
  ),
  Achievement(
    id: 'prayers_100',
    title: '100 Oraciones',
    description: 'Completa 100 oraciones',
    type: AchievementType.prayers,
    target: 100,
    icon: VerbumIcons.handsPraying,
  ),
  Achievement(
    id: 'posts_10',
    title: '10 Publicaciones',
    description: 'Crea 10 publicaciones',
    type: AchievementType.posts,
    target: 10,
    icon: VerbumIcons.chatsCircle,
  ),
  Achievement(
    id: 'posts_50',
    title: '50 Publicaciones',
    description: 'Crea 50 publicaciones',
    type: AchievementType.posts,
    target: 50,
    icon: VerbumIcons.chatsCircle,
  ),
];
