import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/spiritual_stats.dart';
import 'package:verbum/design_system/design_system.dart';

class AchievementDetailScreen extends StatelessWidget {
  final Achievement achievement;
  final SpiritualStats stats;

  const AchievementDetailScreen({
    super.key,
    required this.achievement,
    required this.stats,
  });

  String _getHowToUnlockText() {
    switch (achievement.type) {
      case AchievementType.streak:
        return 'Mantén tu constancia ${achievement.target} días seguidos';
      case AchievementType.verses:
        return 'Lee ${achievement.target} versículos';
      case AchievementType.prayers:
        return 'Completa ${achievement.target} oraciones';
      case AchievementType.posts:
        return 'Crea ${achievement.target} publicaciones';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final unlocked = achievement.isUnlocked(stats);
    final progress = achievement.getProgress(stats);
    final remaining = (achievement.target - progress).clamp(
      0,
      achievement.target,
    );

    return Scaffold(
      appBar: VAppBar(title: Text('Logro', style: context.type.heading)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          12,
          VerbumSpace.gutter,
          32,
        ),
        children: [
          Center(
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? p.goldSoft : p.surfaceMuted,
                border: Border.all(
                  color: unlocked ? p.gold : p.line,
                  width: unlocked ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Hero(
                tag: 'achievement_icon_${achievement.id}',
                child: VIcon(
                  achievement.icon,
                  weight: unlocked ? VIconWeight.fill : VIconWeight.duotone,
                  size: 60,
                  color: unlocked ? p.gold : p.inkSubtle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: VRubricLabel(
              unlocked ? 'Logro alcanzado' : 'En camino',
              color: unlocked ? p.gold : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: type.display.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: type.body.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 24),
          VSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Progreso', style: type.bodyStrong)),
                    Text(
                      '$progress / ${achievement.target}',
                      style: type.bodyStrong.copyWith(color: p.rubric),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                VProgressBar(
                  value: progress / achievement.target,
                  height: 6,
                  semanticLabel: 'Progreso del logro',
                ),
                const SizedBox(height: 10),
                Text(
                  unlocked
                      ? 'Lo alcanzaste. Sigue cultivando tu camino.'
                      : remaining == 1
                      ? 'Te falta 1 para alcanzarlo.'
                      : 'Te faltan $remaining para alcanzarlo.',
                  style: type.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VActionTile(
            tone: VSurfaceTone.muted,
            icon: VerbumIcons.path,
            overline: 'Cómo alcanzarlo',
            title: _getHowToUnlockText(),
            iconColor: p.gold,
            trailingIcon: null,
          ),
        ],
      ),
    );
  }
}
