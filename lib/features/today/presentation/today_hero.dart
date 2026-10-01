import 'package:flutter/material.dart';

import '../../../controllers/missions_controller.dart';
import '../../../design_system/design_system.dart';
import '../application/day_moments.dart';
import '../application/today_schedule.dart';
import 'moments_fan.dart';

/// La cabecera periwinkle de "Hoy": perfil y racha, título con la fecha,
/// el abanico de momentos y la Palabra del día.
/// Solo compone; el estado vive en la pantalla.
class TodayHero extends StatelessWidget {
  const TodayHero({
    super.key,
    required this.now,
    required this.missions,
    required this.streakDays,
    required this.onOpen,
    required this.onProfile,
    required this.onStreak,
    this.verseText,
  });

  final DateTime now;

  /// Todos los momentos, esenciales y la noche opcional, en orden.
  final List<Mission> missions;
  final int streakDays;
  final ValueChanged<Mission> onOpen;
  final VoidCallback onProfile;
  final VoidCallback onStreak;
  final String? verseText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final essentials = missions.where((m) => !m.isOptional);
    final complete = essentials.every((m) => m.completed);
    final verse = missions.where((m) => m.id == 'verse').firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VerbumSpace.gutter),
          child: Row(
            children: [
              _GlassButton(
                icon: VerbumIcons.user,
                tooltip: 'Mi perfil',
                onTap: onProfile,
              ),
              const Spacer(),
              _StreakChip(days: streakDays, onTap: onStreak),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Semantics(
          header: true,
          child: Text(
            complete ? 'Camino de hoy completo' : 'Tu camino de hoy',
            textAlign: TextAlign.center,
            style: type.title.copyWith(color: p.onInverse),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: VerbumSpace.gutter),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: p.onInverse.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VIcon(
                  VerbumIcons.calendarBlank,
                  size: 16,
                  weight: VIconWeight.fill,
                  color: p.butter,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    longSpanishDate(now).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.rubric.copyWith(
                      color: p.onInverse,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        MomentsFan(
          moments: dayMomentsFor(missions),
          nightAvailable: isNightPrayerAvailable(now),
          onOpen: (m) => onOpen(m.mission),
        ),
        if (verse != null && (verseText?.trim().isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              18,
              VerbumSpace.gutter,
              0,
            ),
            child: _VerseOfDay(text: verseText!, onTap: () => onOpen(verse)),
          ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final VerbumIcons icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.onInverse.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(VerbumRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VerbumRadius.control),
          child: SizedBox.square(
            dimension: 48,
            child: Center(child: VIcon(icon, color: p.onInverse)),
          ),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days, required this.onTap});

  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: 'Constancia: $days ${days == 1 ? 'día' : 'días'}',
      excludeSemantics: true,
      child: Material(
        color: p.butter,
        borderRadius: BorderRadius.circular(VerbumRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VerbumRadius.control),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VIcon(
                  VerbumIcons.flame,
                  size: 18,
                  weight: VIconWeight.fill,
                  color: p.onButter,
                ),
                const SizedBox(width: 6),
                Text(
                  '$days ${days == 1 ? 'día' : 'días'}',
                  style: context.type.bodyStrong.copyWith(color: p.onButter),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseOfDay extends StatelessWidget {
  const _VerseOfDay({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Material(
      color: p.onInverse.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(VerbumRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VerbumRadius.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PALABRA DE HOY',
                style: type.rubric.copyWith(
                  color: p.butter,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '«${text.trim()}»',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: type.scripture.copyWith(
                  color: p.onInverse,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
