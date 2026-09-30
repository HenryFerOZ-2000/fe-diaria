import 'package:flutter/material.dart';

import '../../../controllers/missions_controller.dart';
import '../../../design_system/design_system.dart';
import 'journey_complete_card.dart';
import 'journey_steps_row.dart';
import 'next_step_card.dart';
import 'night_invitation_card.dart';

/// Sección "Tu camino de hoy": siguiente paso, recorrido y cierre nocturno.
/// Solo compone; el estado vive en la pantalla.
class TodayJourneySection extends StatelessWidget {
  const TodayJourneySection({
    super.key,
    required this.essentials,
    required this.nextMission,
    required this.optionalMission,
    required this.nightAvailable,
    required this.onOpen,
    this.verseText,
    this.verseReference,
  });

  final List<Mission> essentials;
  final Mission? nextMission;
  final Mission? optionalMission;
  final bool nightAvailable;
  final ValueChanged<Mission> onOpen;
  final String? verseText;
  final String? verseReference;

  @override
  Widget build(BuildContext context) {
    final completed = essentials.where((m) => m.completed).length;
    final next = nextMission;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSectionHeader(
          'Tu camino de hoy',
          trailing: '$completed de ${essentials.length}',
          padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          child: next != null
              ? NextStepCard(
                  key: ValueKey(next.id),
                  mission: next,
                  verseText: verseText,
                  verseReference: verseReference,
                  onStart: () => onOpen(next),
                )
              : const JourneyCompleteCard(key: ValueKey('complete')),
        ),
        const SizedBox(height: 10),
        JourneyStepsRow(
          missions: essentials,
          nextMission: next,
          onOpen: onOpen,
        ),
        if (optionalMission != null) ...[
          const SizedBox(height: 10),
          NightInvitationCard(
            mission: optionalMission!,
            available: nightAvailable,
            onOpen: () => onOpen(optionalMission!),
          ),
        ],
      ],
    );
  }
}
