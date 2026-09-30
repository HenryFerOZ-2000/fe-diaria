import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../application/constancy_progress.dart';

/// Constancia (racha): días seguidos, semana actual y avance al próximo hito.
class ConstancyCard extends StatelessWidget {
  const ConstancyCard({
    super.key,
    required this.progress,
    required this.weekLabels,
    required this.weekCompleted,
    required this.todayIndex,
    this.celebrate = false,
    this.onTap,
  }) : assert(weekLabels.length == weekCompleted.length);

  final ConstancyProgress progress;
  final List<String> weekLabels;
  final List<bool> weekCompleted;

  /// Índice del día de hoy dentro de la semana (0 = lunes).
  final int todayIndex;

  /// Anima la llama (tras completar el día).
  final bool celebrate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final animate = celebrate && !MediaQuery.disableAnimationsOf(context);

    return VSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      semanticLabel:
          '${progress.daysLabel} de constancia. ${progress.todayMessage}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: animate ? 0.6 : 1, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.goldSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: VIcon(
                    VerbumIcons.flame,
                    weight: progress.totalDays > 0
                        ? VIconWeight.fill
                        : VIconWeight.duotone,
                    size: 24,
                    color: p.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VRubricLabel('Tu constancia'),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${progress.totalDays}',
                            style: type.title.copyWith(fontSize: 26),
                          ),
                          TextSpan(
                            text: progress.totalDays == 1
                                ? '  día caminando'
                                : '  días caminando',
                            style: type.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              VIcon(VerbumIcons.caretRight, size: 18, color: p.inkSubtle),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < weekLabels.length; i++)
                Expanded(
                  child: _WeekDot(
                    label: weekLabels[i],
                    done: weekCompleted[i],
                    today: i == todayIndex,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          VProgressBar(
            value: progress.progress,
            semanticLabel: 'Avance hacia ${progress.nextMilestone} días',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(progress.todayMessage, style: type.caption)),
              Text(
                'Meta: ${progress.nextMilestone} días',
                style: type.caption.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.label,
    required this.done,
    required this.today,
  });

  final String label;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Column(
      children: [
        Text(
          label,
          style: type.caption.copyWith(
            fontWeight: today ? FontWeight.w800 : FontWeight.w600,
            color: today ? p.ink : p.inkSubtle,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? p.ink : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? p.ink : (today ? p.rubric : p.line),
              width: today && !done ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? VIcon(VerbumIcons.check, size: 14, color: p.gold)
              : today
              ? Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.rubric,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
