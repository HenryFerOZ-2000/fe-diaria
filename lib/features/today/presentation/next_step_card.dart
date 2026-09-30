import 'package:flutter/material.dart';

import '../../../controllers/missions_controller.dart';
import '../../../design_system/design_system.dart';
import 'mission_visuals.dart';

/// La pieza principal de "Hoy": el siguiente momento del camino.
///
/// Si el momento es la Palabra y ya se conoce el versículo, lo muestra con
/// capitular, como un libro de horas.
class NextStepCard extends StatelessWidget {
  const NextStepCard({
    super.key,
    required this.mission,
    required this.onStart,
    this.verseText,
    this.verseReference,
  });

  final Mission mission;
  final VoidCallback onStart;
  final String? verseText;
  final String? verseReference;

  bool get _showsVerse =>
      mission.id == 'verse' && (verseText?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    return VSurfaceCard(
      framed: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: VRubricLabel(
                  _showsVerse ? 'Palabra del día' : 'Tu siguiente paso',
                  icon: _showsVerse ? VerbumIcons.quotes : null,
                ),
              ),
              VIcon(
                iconForMission(mission),
                weight: VIconWeight.duotone,
                size: 26,
                color: p.gold,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_showsVerse) ...[
            VDropCapText(verseText!.trim(), style: type.scriptureLarge),
            if (verseReference != null) ...[
              const SizedBox(height: 10),
              Text(verseReference!, style: type.citation),
            ],
          ] else ...[
            Text(mission.title, style: type.title),
            const SizedBox(height: 8),
            Text(mission.description, style: type.body),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: p.lineSoft),
          const SizedBox(height: 12),
          Row(
            children: [
              VMetaChip(
                icon: VerbumIcons.clock,
                label: '${mission.durationMinutes} min',
              ),
              const Spacer(),
              VButton(
                label: mission.completed ? 'Volver a leer' : 'Comenzar',
                icon: VerbumIcons.arrowRight,
                compact: true,
                onPressed: onStart,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
