import 'package:flutter/material.dart';

import '../../../controllers/missions_controller.dart';
import '../../../design_system/design_system.dart';
import '../application/day_moments.dart';
import 'journey_complete_card.dart';
import 'moments_fan.dart';

/// Sección "Tu camino de hoy": el abanico de momentos del día.
/// Solo compone; el estado vive en la pantalla.
class TodayJourneySection extends StatelessWidget {
  const TodayJourneySection({
    super.key,
    required this.missions,
    required this.nightAvailable,
    required this.onOpen,
    this.verseText,
    this.verseReference,
  });

  /// Todos los momentos, esenciales y la noche opcional, en orden.
  final List<Mission> missions;
  final bool nightAvailable;
  final ValueChanged<Mission> onOpen;
  final String? verseText;
  final String? verseReference;

  @override
  Widget build(BuildContext context) {
    final essentials = missions.where((m) => !m.isOptional);
    final completed = essentials.where((m) => m.completed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSectionHeader(
          'Tu camino de hoy',
          trailing: '$completed de ${essentials.length}',
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 6),
        ),
        if (completed == essentials.length) ...[
          const JourneyCompleteCard(),
          const SizedBox(height: 6),
        ],
        MomentsFan(
          moments: dayMomentsFor(missions),
          nightAvailable: nightAvailable,
          verseText: verseText,
          verseReference: verseReference,
          onOpen: (m) => onOpen(m.mission),
        ),
      ],
    );
  }
}
