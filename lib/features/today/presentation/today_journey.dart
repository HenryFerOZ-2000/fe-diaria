import 'package:flutter/material.dart';

import '../../../controllers/missions_controller.dart';
import '../../../design_system/design_system.dart';
import '../application/day_moments.dart';
import '../application/today_schedule.dart';
import 'mission_visuals.dart';

/// "Tu siguiente paso" y "Tu día": qué toca ahora y el recorrido del día.
/// Solo compone; el estado vive en la pantalla.
class TodayJourney extends StatelessWidget {
  const TodayJourney({
    super.key,
    required this.missions,
    required this.nightAvailable,
    required this.onOpen,
  });

  /// Todos los momentos, esenciales y la noche opcional, en orden.
  final List<Mission> missions;
  final bool nightAvailable;
  final ValueChanged<Mission> onOpen;

  bool _locked(Mission m) => m.id == 'night' && !nightAvailable && !m.completed;

  @override
  Widget build(BuildContext context) {
    final moments = dayMomentsFor(missions);
    final next = moments.isEmpty ? null : moments[initialMomentIndex(moments)];
    final allDone = moments.every((m) => m.done || m.mission.isOptional);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (next != null)
          _NextStep(
            moment: next,
            allEssentialsDone: allDone,
            locked: _locked(next.mission),
            onOpen: () => onOpen(next.mission),
          ),
        const VSectionHeader(
          'Tu día',
          padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < moments.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: VStepTile(
                    icon: iconForMission(moments[i].mission),
                    title: shortLabelForMission(moments[i].mission),
                    caption: moments[i].done
                        ? 'Hecho'
                        : identical(moments[i], next)
                        ? 'Ahora'
                        : moments[i].time,
                    state: moments[i].done
                        ? VStepState.done
                        : identical(moments[i], next)
                        ? VStepState.current
                        : VStepState.upcoming,
                    onTap: _locked(moments[i].mission)
                        ? null
                        : () => onOpen(moments[i].mission),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.moment,
    required this.allEssentialsDone,
    required this.locked,
    required this.onOpen,
  });

  final DayMoment moment;
  final bool allEssentialsDone;
  final bool locked;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final mission = moment.mission;
    final finished = moment.done;
    final eyebrow = finished
        ? 'Camino de hoy completo'
        : allEssentialsDone
        ? 'Para cerrar el día'
        : 'Tu siguiente paso';
    final detail = locked
        ? 'Disponible desde las $nightPrayerStartHour:00'
        : '${shortLabelForMission(mission)} · ${mission.durationMinutes} min';

    return Semantics(
      button: !locked,
      label: '$eyebrow. ${mission.title}. $detail',
      excludeSemantics: true,
      child: VSurfaceCard(
        onTap: locked ? null : onOpen,
        radius: VerbumRadius.card,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: finished ? p.sageSoft : p.butter,
                borderRadius: BorderRadius.circular(VerbumRadius.control),
              ),
              child: VIcon(
                finished ? VerbumIcons.check : iconForMission(mission),
                size: 24,
                color: finished ? p.sage : p.onButter,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: type.rubric.copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mission.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.heading.copyWith(fontSize: 16),
                  ),
                  Text(detail, style: type.caption),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!locked)
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.emphasis,
                  shape: BoxShape.circle,
                ),
                child: VIcon(
                  finished
                      ? VerbumIcons.arrowCounterClockwise
                      : VerbumIcons.play,
                  size: 18,
                  weight: VIconWeight.fill,
                  color: p.onEmphasis,
                ),
              )
            else
              VIcon(VerbumIcons.lockSimple, size: 20, color: p.inkSubtle),
          ],
        ),
      ),
    );
  }
}
