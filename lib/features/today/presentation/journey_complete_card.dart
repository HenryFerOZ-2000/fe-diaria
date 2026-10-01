import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Se muestra cuando los momentos esenciales del día están completos.
class JourneyCompleteCard extends StatelessWidget {
  const JourneyCompleteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return VSurfaceCard(
      tone: VSurfaceTone.accent,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const VPhotoFrame(VerbumPhotos.sunset, width: 64, tiltDegrees: -5),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu camino de hoy está completo',
                  style: type.heading.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 3),
                Text(
                  'La constancia ya está a salvo. Regresa esta noche si deseas '
                  'cerrar el día en oración.',
                  style: type.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
